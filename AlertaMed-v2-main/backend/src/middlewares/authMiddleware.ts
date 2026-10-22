import { NextFunction, Request, Response } from "express";
import jwt from "jsonwebtoken";
import { pool } from "../config/database";

export async function authMiddleware(
  req: Request,
  res: Response,
  next: NextFunction,
) {
  const authHeader = req.headers.authorization;

  if (!authHeader) {
    return res.status(401).json({
      error: true,
      message: "Token não informado",
    });
  }

  const [type, token] = authHeader.split(" ");

  if (type !== "Bearer" || !token) {
    return res.status(401).json({
      error: true,
      message: "Token inválido",
    });
  }

  const secret = process.env.JWT_SECRET;

  if (!secret) {
    console.error("JWT_SECRET não configurado");

    return res.status(500).json({
      error: true,
      message: "Erro interno de autenticação.",
    });
  }

  let decoded: jwt.JwtPayload;

  try {
    const payload = jwt.verify(token, secret);

    if (
      typeof payload === "string" ||
      typeof payload.userId !== "string" ||
      typeof payload.iat !== "number" ||
      !/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(
        payload.userId,
      )
    ) {
      return res.status(401).json({
        error: true,
        message: "Token inválido",
      });
    }

    decoded = payload;
  } catch {
    return res.status(401).json({
      error: true,
      message: "Token inválido ou expirado",
    });
  }

  try {
    const result = await pool.query(
      `SELECT tokens_valid_after
       FROM users
       WHERE id = $1
       LIMIT 1`,
      [decoded.userId],
    );

    if (result.rows.length === 0) {
      return res.status(401).json({
        error: true,
        message: "Usuário não encontrado",
      });
    }

    const validAfter = Number(result.rows[0].tokens_valid_after);

    if (decoded.iat! < validAfter) {
      return res.status(401).json({
        error: true,
        message: "Sessão invalidada. Faça login novamente.",
      });
    }

    req.userId = decoded.userId;

    next();
  } catch (error) {
    console.error("Erro ao verificar sessão:", error);

    return res.status(500).json({
      error: true,
      message: "Erro interno de autenticação.",
    });
  }
}
