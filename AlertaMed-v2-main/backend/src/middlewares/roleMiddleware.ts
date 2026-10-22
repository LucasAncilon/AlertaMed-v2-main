import type { Request, Response, NextFunction } from "express";
import { pool } from "../config/database";

type UserRole = "client" | "caregiver";

export function requireRole(...allowedRoles: UserRole[]) {
  return async (req: Request, res: Response, next: NextFunction) => {
    try {
      // O authMiddleware deve executar primeiro.
      if (!req.userId) {
        return res.status(401).json({
          error: true,
          message: "Usuário não autenticado.",
        });
      }

      const result = await pool.query("SELECT role FROM users WHERE id = $1", [
        req.userId,
      ]);

      if (result.rows.length === 0) {
        return res.status(401).json({
          error: true,
          message: "Usuário não encontrado.",
        });
      }

      const role = result.rows[0].role;

      if (!allowedRoles.includes(role)) {
        return res.status(403).json({
          error: true,
          message: "Você não tem permissão para acessar este recurso.",
        });
      }

      next();
    } catch (error) {
      console.error("Erro ao verificar permissão:", error);

      return res.status(500).json({
        error: true,
        message: "Erro interno ao verificar permissão.",
      });
    }
  };
}
