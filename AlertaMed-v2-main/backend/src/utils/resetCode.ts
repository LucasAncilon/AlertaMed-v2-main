import { randomInt, createHmac } from "crypto";

// Gera um código aleatório de 6 dígitos.
export function generateResetCode(): string {
  return randomInt(0, 1000000).toString().padStart(6, "0");
}

// Gera uma assinatura segura do código para
// armazenar no banco sem guardar o código original.
export function hashResetCode(code: string): string {
  const secret = process.env.RESET_CODE_SECRET;

  if (!secret) {
    throw new Error("RESET_CODE_SECRET não configurado.");
  }

  return createHmac("sha256", secret).update(code).digest("hex");
}
