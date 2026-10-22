import { Request, Response } from "express";
import { pool } from "../config/database";
import { generateLinkCode, hashLinkCode } from "../utils/linkCode";

export async function createLinkCode(req: Request, res: Response) {
  try {
    const clientId = req.userId;

    if (!clientId) {
      return res.status(401).json({
        error: true,
        message: "Usuário não autenticado.",
      });
    }

    const code = generateLinkCode();
    const codeHash = hashLinkCode(code);

    const result = await pool.query(
      `INSERT INTO link_codes (client_id, code_hash, expires_at)
       VALUES ($1, $2, NOW() + INTERVAL '15 minutes')
       RETURNING expires_at`,
      [clientId, codeHash],
    );

    return res.status(201).json({
      message: "Código de vínculo gerado com sucesso!",
      code,
      expiresAt: result.rows[0].expires_at,
    });
  } catch (error) {
    console.error("Erro ao gerar código de vínculo:", error);

    return res.status(500).json({
      error: true,
      message: "Erro interno ao gerar código de vínculo.",
    });
  }
}

export async function useLinkCode(req: Request, res: Response) {
  const caregiverId = req.userId;
  const { code } = req.body ?? {};

  if (!caregiverId) {
    return res.status(401).json({
      error: true,
      message: "Usuário não autenticado.",
    });
  }

  if (typeof code !== "string" || !/^[A-HJ-NP-Z2-9]{8}$/i.test(code.trim())) {
    return res.status(400).json({
      error: true,
      message: "Código de vínculo inválido.",
    });
  }

  let codeHash: string;

  try {
    codeHash = hashLinkCode(code);
  } catch (error) {
    console.error("Erro ao proteger código:", error);
    return res.status(500).json({
      error: true,
      message: "Erro interno ao validar código.",
    });
  }

  const db = await pool.connect();
  let transactionStarted = false;

  try {
    await db.query("BEGIN");
    transactionStarted = true;

    // Bloqueia o código durante a transação para impedir uso simultâneo.
    const result = await db.query(
      `SELECT id, client_id, expires_at, used_at
       FROM link_codes
       WHERE code_hash = $1
       FOR UPDATE`,
      [codeHash],
    );

    if (result.rows.length === 0) {
      await db.query("ROLLBACK");
      return res.status(400).json({
        error: true,
        message: "Código inválido ou não encontrado.",
      });
    }

    const linkCode = result.rows[0];

    if (linkCode.used_at !== null) {
      await db.query("ROLLBACK");
      return res.status(409).json({
        error: true,
        message: "Este código já foi utilizado.",
      });
    }

    if (new Date(linkCode.expires_at).getTime() <= Date.now()) {
      await db.query("ROLLBACK");
      return res.status(410).json({
        error: true,
        message: "Este código expirou.",
      });
    }

    if (linkCode.client_id === caregiverId) {
      await db.query("ROLLBACK");
      return res.status(400).json({
        error: true,
        message: "Não é possível vincular uma conta a ela mesma.",
      });
    }

    // Verifica se o acompanhante já possui vínculo com o cliente.
    const existing = await db.query(
      `SELECT id
       FROM caregiver_client_links
       WHERE caregiver_id = $1 AND client_id = $2`,
      [caregiverId, linkCode.client_id],
    );

    if (existing.rows.length > 0) {
      await db.query("ROLLBACK");
      return res.status(409).json({
        error: true,
        message: "Este acompanhante já está vinculado ao cliente.",
      });
    }

    // Cria o vínculo.
    await db.query(
      `INSERT INTO caregiver_client_links (caregiver_id, client_id)
       VALUES ($1, $2)`,
      [caregiverId, linkCode.client_id],
    );

    // Marca o código como utilizado.
    await db.query(
      `UPDATE link_codes
       SET used_at = NOW()
       WHERE id = $1`,
      [linkCode.id],
    );

    await db.query("COMMIT");
    transactionStarted = false;

    return res.status(201).json({
      message: "Vínculo criado com sucesso!",
      clientId: linkCode.client_id,
    });
  } catch (error) {
    if (transactionStarted) {
      await db.query("ROLLBACK").catch(console.error);
    }

    console.error("Erro ao utilizar código de vínculo:", error);

    return res.status(500).json({
      error: true,
      message: "Erro interno ao criar vínculo.",
    });
  } finally {
    db.release();
  }
}
