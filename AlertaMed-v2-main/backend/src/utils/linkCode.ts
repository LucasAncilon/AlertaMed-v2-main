import { randomInt, createHmac } from "crypto";

// Removemos caracteres que podem ser confundidos,
// como 0/O e 1/I.
const CHARACTERS = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";

export function generateLinkCode(): string {
  let code = "";

  for (let i = 0; i < 8; i++) {
    const index = randomInt(CHARACTERS.length);
    code += CHARACTERS[index];
  }

  return code;
}

// Gera uma representação protegida do código.
// O segredo deve ser diferente do JWT_SECRET.
export function hashLinkCode(code: string): string {
  const secret = process.env.LINK_CODE_SECRET;

  if (!secret) {
    throw new Error("LINK_CODE_SECRET não configurado");
  }

  return createHmac("sha256", secret)
    .update(code.trim().toUpperCase())
    .digest("hex");
}
