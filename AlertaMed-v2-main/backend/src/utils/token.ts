import jwt from "jsonwebtoken";
import type { SignOptions } from "jsonwebtoken";

export function generateToken(userId: string, tokensValidAfter = 0) {
  const secret = process.env.JWT_SECRET;

  const expiresIn = (process.env.JWT_EXPIRES_IN ||
    "1h") as SignOptions["expiresIn"];

  if (!secret) {
    throw new Error("JWT_SECRET não configurado");
  }

  const issuedAt = Math.max(Math.floor(Date.now() / 1000), tokensValidAfter);

  return jwt.sign(
    {
      userId,
      iat: issuedAt,
    },
    secret,
    { expiresIn },
  );
}
