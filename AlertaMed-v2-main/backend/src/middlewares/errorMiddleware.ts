import { NextFunction, Request, Response } from "express";

export function errorMiddleware(
  error: Error,
  req: Request,
  res: Response,
  next: NextFunction,
) {
  console.error("Erro interno:", error);

  return res.status(500).json({
    error: true,
    message: "Erro interno do servidor",
  });
}
