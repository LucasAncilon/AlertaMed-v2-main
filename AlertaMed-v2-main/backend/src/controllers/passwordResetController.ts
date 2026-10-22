import { Request, Response } from "express";
import { timingSafeEqual } from "crypto";
import { pool } from "../config/database";
import { hashPassword } from "../utils/password";
import { generateResetCode, hashResetCode } from "../utils/resetCode";
import { sendResetCodeEmail } from "../services/emailService";

const GENERIC_MESSAGE =
  "Se o e-mail estiver cadastrado, você receberá um código de recuperação.";

export async function forgotPassword(req: Request, res: Response) {
  try {
    const { email } = req.body ?? {};

    if (typeof email !== "string" || !email.trim() || email.length > 255) {
      return res.status(400).json({
        error: true,
        message: "Informe um e-mail válido.",
      });
    }

    const normalizedEmail = email.trim().toLowerCase();

    const result = await pool.query(
      `SELECT id, email
       FROM users
       WHERE LOWER(email) = $1
       LIMIT 1`,
      [normalizedEmail],
    );

    // Não revelar se a conta existe.
    if (result.rows.length === 0) {
      return res.status(200).json({
        message: GENERIC_MESSAGE,
      });
    }

    const user = result.rows[0];
    const code = generateResetCode();
    const codeHash = hashResetCode(code);

    // Um código por usuário, com intervalo mínimo
    // de 60 segundos entre solicitações.
    const saved = await pool.query(
      `INSERT INTO password_reset_codes
         (user_id, code_hash, expires_at)
       VALUES ($1, $2, NOW() + INTERVAL '10 minutes')
       ON CONFLICT (user_id)
       DO UPDATE SET
         code_hash = EXCLUDED.code_hash,
         expires_at = EXCLUDED.expires_at,
         attempts = 0,
         created_at = NOW()
       WHERE password_reset_codes.created_at
         <= NOW() - INTERVAL '60 seconds'
       RETURNING id`,
      [user.id, codeHash],
    );

    if (saved.rowCount) {
      try {
        await sendResetCodeEmail(user.email, code);
      } catch (emailError) {
        console.error("Falha ao enviar código de recuperação:", emailError);

        // Remove somente o código que acabamos
        // de gerar, caso o envio tenha falhado.
        await pool.query(
          `DELETE FROM password_reset_codes
       WHERE user_id = $1 AND code_hash = $2`,
          [user.id, codeHash],
        );
      }
    }

    return res.status(200).json({
      message: GENERIC_MESSAGE,
    });
  } catch (error) {
    console.error("Erro ao solicitar recuperação:", error);

    return res.status(500).json({
      error: true,
      message: "Não foi possível processar a solicitação.",
    });
  }
}

export async function resetPassword(req: Request, res: Response) {
  const client = await pool.connect();

  try {
    const { email, code, newPassword } = req.body ?? {};

    if (
      typeof email !== "string" ||
      typeof code !== "string" ||
      typeof newPassword !== "string" ||
      !email.trim() ||
      email.length > 255 ||
      !/^\d{6}$/.test(code) ||
      newPassword.length < 8 ||
      newPassword.length > 72
    ) {
      return res.status(400).json({
        error: true,
        message: "Dados inválidos. A senha deve ter entre 8 e 72 caracteres.",
      });
    }

    const normalizedEmail = email.trim().toLowerCase();

    await client.query("BEGIN");

    const result = await client.query(
      `SELECT u.id, p.code_hash, p.expires_at, p.attempts
       FROM users u
       JOIN password_reset_codes p ON p.user_id = u.id
       WHERE LOWER(u.email) = $1
       FOR UPDATE OF p`,
      [normalizedEmail],
    );

    const invalidMessage = {
      error: true,
      message: "Código inválido ou expirado. Solicite um novo código.",
    };

    if (result.rows.length === 0) {
      await client.query("COMMIT");
      return res.status(400).json(invalidMessage);
    }

    const record = result.rows[0];

    if (
      record.attempts >= 5 ||
      new Date(record.expires_at).getTime() <= Date.now()
    ) {
      await client.query("COMMIT");
      return res.status(400).json(invalidMessage);
    }

    const receivedHash = Buffer.from(hashResetCode(code), "hex");
    const storedHash = Buffer.from(record.code_hash, "hex");

    const validCode =
      receivedHash.length === storedHash.length &&
      timingSafeEqual(receivedHash, storedHash);

    if (!validCode) {
      await client.query(
        `UPDATE password_reset_codes
         SET attempts = attempts + 1
         WHERE user_id = $1`,
        [record.id],
      );

      await client.query("COMMIT");
      return res.status(400).json(invalidMessage);
    }

    const newHash = await hashPassword(newPassword);

    await client.query(
      `UPDATE users
   SET password_hash = $1,
       tokens_valid_after = FLOOR(EXTRACT(EPOCH FROM NOW()))::BIGINT + 1
   WHERE id = $2`,
      [newHash, record.id],
    );

    // Invalidar imediatamente o código utilizado.
    await client.query(
      `DELETE FROM password_reset_codes
       WHERE user_id = $1`,
      [record.id],
    );

    await client.query("COMMIT");

    return res.status(200).json({
      message: "Senha alterada com sucesso! Faça login novamente.",
    });
  } catch (error) {
    try {
      await client.query("ROLLBACK");
    } catch (rollbackError) {
      console.error("Erro ao desfazer transação:", rollbackError);
    }

    console.error("Erro ao redefinir senha:", error);

    return res.status(500).json({
      error: true,
      message: "Erro interno ao redefinir senha.",
    });
  } finally {
    client.release();
  }
}
