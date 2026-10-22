import { Request, Response } from "express";
import { hashPassword, comparePassword } from "../utils/password";
import { generateToken } from "../utils/token";
import { pool } from "../config/database";

export async function register(req: Request, res: Response) {
  try {
    const { name, email, password, role } = req.body;

    // 1. Verificar os dados recebidos
    if (
      typeof name !== "string" ||
      typeof email !== "string" ||
      typeof password !== "string" ||
      typeof role !== "string" ||
      !name.trim() ||
      !email.trim() ||
      !password
    ) {
      return res.status(400).json({
        error: true,
        message: "Nome, email, senha e tipo de conta são obrigatórios.",
      });
    }

    if (role !== "client" && role !== "caregiver") {
      return res.status(400).json({
        error: true,
        message: "Tipo de conta inválido.",
      });
    }

    const normalizedName = name.trim();
    const normalizedEmail = email.trim().toLowerCase();

    if (
      normalizedEmail.length > 255 ||
      normalizedName.length > 150 ||
      !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(normalizedEmail)
    ) {
      return res.status(400).json({
        error: true,
        message: "Nome ou email inválido.",
      });
    }

    if (password.length < 8 || password.length > 72) {
      return res.status(400).json({
        error: true,
        message: "A senha deve ter entre 8 e 72 caracteres.",
      });
    }

    // 2. Gerar o hash da senha
    const passwordHash = await hashPassword(password);

    // 3. Salvar o usuário no PostgreSQL
    const result = await pool.query(
      `INSERT INTO users (name, email, password_hash, role)
       VALUES ($1, $2, $3, $4)
       RETURNING id, name, email, role, created_at`,
      [normalizedName, normalizedEmail, passwordHash, role],
    );

    // 4. Retornar os dados públicos
    return res.status(201).json({
      message: "Usuário cadastrado com sucesso!",
      user: result.rows[0],
    });
  } catch (error: unknown) {
    // PostgreSQL: violação de índice único
    if (
      typeof error === "object" &&
      error !== null &&
      "code" in error &&
      error.code === "23505"
    ) {
      return res.status(409).json({
        error: true,
        message: "Este email já está cadastrado.",
      });
    }

    console.error("Erro no cadastro:", error);

    return res.status(500).json({
      error: true,
      message: "Erro interno ao cadastrar usuário.",
    });
  }
}

export async function login(req: Request, res: Response) {
  try {
    const { email, password } = req.body;

    // 1. Validar os dados recebidos
    if (
      typeof email !== "string" ||
      typeof password !== "string" ||
      !email.trim() ||
      !password
    ) {
      return res.status(400).json({
        error: true,
        message: "Email e senha são obrigatórios.",
      });
    }

    const normalizedEmail = email.trim().toLowerCase();

    // 2. Buscar o usuário no PostgreSQL
    const result = await pool.query(
      `SELECT id, name, email, password_hash, role,
          tokens_valid_after
   FROM users
   WHERE LOWER(email) = $1
   LIMIT 1`,
      [normalizedEmail],
    );

    // 3. Verificar se o usuário existe
    if (result.rows.length === 0) {
      return res.status(401).json({
        error: true,
        message: "Email ou senha inválidos.",
      });
    }

    const user = result.rows[0];

    // 4. Verificar a senha usando bcrypt
    const passwordIsValid = await comparePassword(password, user.password_hash);

    if (!passwordIsValid) {
      return res.status(401).json({
        error: true,
        message: "Email ou senha inválidos.",
      });
    }

    // 5. Gerar o JWT com o UUID do usuário
    const token = generateToken(user.id, Number(user.tokens_valid_after));

    // 6. Retornar o resultado
    return res.status(200).json({
      message: "Login realizado com sucesso!",
      token,
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role,
      },
    });
  } catch (error) {
    console.error("Erro no login:", error);

    return res.status(500).json({
      error: true,
      message: "Erro interno ao realizar login.",
    });
  }
}

export async function getAuthenticatedUser(req: Request, res: Response) {
  try {
    const userId = req.userId;

    if (!userId) {
      return res.status(401).json({
        error: true,
        message: "Usuário não autenticado.",
      });
    }

    const result = await pool.query(
      `SELECT id, name, email, role
       FROM users
       WHERE id = $1
       LIMIT 1`,
      [userId],
    );

    if (result.rows.length === 0) {
      return res.status(401).json({
        error: true,
        message: "Usuário não encontrado.",
      });
    }

    return res.status(200).json({
      message: "Sessão válida.",
      user: result.rows[0],
    });
  } catch (error) {
    console.error("Erro ao recuperar usuário:", error);

    return res.status(500).json({
      error: true,
      message: "Erro interno ao verificar sessão.",
    });
  }
}
