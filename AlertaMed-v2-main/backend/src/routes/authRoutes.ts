import { Router } from "express";
import {
  register,
  login,
  getAuthenticatedUser,
} from "../controllers/authController";
import { authMiddleware } from "../middlewares/authMiddleware";
import { requireRole } from "../middlewares/roleMiddleware";
import { createLinkCode, useLinkCode } from "../controllers/linkController";
import {
  listLinkedClients,
  checkClientAccess,
} from "../controllers/caregiverController";
import {
  forgotPassword,
  resetPassword,
} from "../controllers/passwordResetController";
import {
  forgotPasswordLimiter,
  resetPasswordLimiter,
} from "../middlewares/passwordResetLimiter";

const authRoutes = Router();

authRoutes.post("/register", register);
authRoutes.post("/login", login);

authRoutes.post("/forgot-password", forgotPasswordLimiter, forgotPassword);

authRoutes.post("/reset-password", resetPasswordLimiter, resetPassword);

authRoutes.get("/protected", authMiddleware, (req, res) => {
  res.json({
    message: "Acesso autorizado!",
    userId: req.userId,
  });
});

authRoutes.get(
  "/client-only",
  authMiddleware,
  requireRole("client"),
  (req, res) => {
    res.status(200).json({
      message: "Acesso permitido para cliente!",
      userId: req.userId,
    });
  },
);

authRoutes.get(
  "/caregiver-only",
  authMiddleware,
  requireRole("caregiver"),
  (req, res) => {
    res.status(200).json({
      message: "Acesso permitido para acompanhante!",
      userId: req.userId,
    });
  },
);

authRoutes.post(
  "/link-code",
  authMiddleware,
  requireRole("client"),
  createLinkCode,
);

authRoutes.post(
  "/use-link-code",
  authMiddleware,
  requireRole("caregiver"),
  useLinkCode,
);

authRoutes.get(
  "/linked-clients",
  authMiddleware,
  requireRole("caregiver"),
  listLinkedClients,
);

authRoutes.get(
  "/clients/:clientId/access",
  authMiddleware,
  requireRole("caregiver"),
  checkClientAccess,
);

authRoutes.get("/me", authMiddleware, getAuthenticatedUser);

export default authRoutes;
