import { Request, Response } from "express";
import { pool } from "../config/database";

export async function listLinkedClients(req: Request, res: Response) {
  try {
    const caregiverId = req.userId;

    if (!caregiverId) {
      return res.status(401).json({
        error: true,
        message: "Usuário não autenticado.",
      });
    }

    const result = await pool.query(
      `SELECT
         u.id,
         u.name,
         l.created_at AS linked_at
       FROM caregiver_client_links l
       INNER JOIN users u ON u.id = l.client_id
       WHERE l.caregiver_id = $1
         AND u.role = 'client'
       ORDER BY u.name`,
      [caregiverId],
    );

    return res.status(200).json({
      message: "Clientes vinculados consultados com sucesso!",
      clients: result.rows,
    });
  } catch (error) {
    console.error("Erro ao listar clientes vinculados:", error);

    return res.status(500).json({
      error: true,
      message: "Erro interno ao consultar clientes vinculados.",
    });
  }
}

export async function checkClientAccess(req: Request, res: Response) {
  try {
    const caregiverId = req.userId;
    const clientId = req.params.clientId;

    if (!caregiverId) {
      return res.status(401).json({
        error: true,
        message: "Usuário não autenticado.",
      });
    }

    if (
      typeof clientId !== "string" ||
      !/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(
        clientId,
      )
    ) {
      return res.status(400).json({
        error: true,
        message: "Identificador do cliente inválido.",
      });
    }

    const result = await pool.query(
      `SELECT 1
       FROM caregiver_client_links l
       INNER JOIN users u ON u.id = l.client_id
       WHERE l.caregiver_id = $1
         AND l.client_id = $2
         AND u.role = 'client'
       LIMIT 1`,
      [caregiverId, clientId],
    );

    if (result.rows.length === 0) {
      return res.status(403).json({
        error: true,
        message: "Acesso negado: cliente não vinculado.",
      });
    }

    return res.status(200).json({
      message: "Acesso autorizado ao cliente!",
      clientId,
    });
  } catch (error) {
    console.error("Erro ao verificar vínculo:", error);

    return res.status(500).json({
      error: true,
      message: "Erro interno ao verificar acesso ao cliente.",
    });
  }
}
