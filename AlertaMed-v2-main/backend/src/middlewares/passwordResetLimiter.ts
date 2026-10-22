import { rateLimit } from "express-rate-limit";

// Limita solicitações de códigos de recuperação.
export const forgotPasswordLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 5,
  standardHeaders: "draft-8",
  legacyHeaders: false,
  message: {
    error: true,
    message: "Muitas solicitações. Tente novamente mais tarde.",
  },
});

// Limita tentativas de redefinição de senha.
export const resetPasswordLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 10,
  standardHeaders: "draft-8",
  legacyHeaders: false,
  message: {
    error: true,
    message: "Muitas tentativas. Tente novamente mais tarde.",
  },
});
