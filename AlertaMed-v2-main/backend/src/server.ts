import express from "express";
import authRoutes from "./routes/authRoutes";
import { pool } from "./config/database";
import { errorMiddleware } from "./middlewares/errorMiddleware";

const app = express();
const PORT = 3000;

app.use(express.json());

app.get("/", (req, res) => {
  res.json({
    message: "API do AlertaMed funcionando!",
  });
});

app.use("/auth", authRoutes);
app.use(errorMiddleware);

async function startServer() {
  try {
    const result = await pool.query("SELECT NOW()");

    console.log("PostgreSQL conectado com sucesso!");
    console.log("Horário do banco:", result.rows[0].now);

    app.listen(PORT, () => {
      console.log(`Servidor rodando em http://localhost:${PORT}`);
    });
  } catch (error) {
    console.error("Erro ao conectar com o PostgreSQL:");
    console.error(error);
  }
}

startServer();
