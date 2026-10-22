import "dotenv/config";
import nodemailer from "nodemailer";

export async function sendResetCodeEmail(
  email: string,
  code: string,
): Promise<void> {
  const smtpUser = process.env.SMTP_USER;
  const smtpPassword = process.env.SMTP_PASSWORD;

  if (!smtpUser || !smtpPassword) {
    throw new Error("Configuração SMTP incompleta.");
  }

  const transporter = nodemailer.createTransport({
    host: "smtp.gmail.com",
    port: 465,
    secure: true,
    auth: {
      user: smtpUser,
      pass: smtpPassword,
    },
  });

  await transporter.sendMail({
    from: `"AlertaMed" <${smtpUser}>`,
    to: email,
    subject: "AlertaMed - Recuperação de senha",
    text: `Olá!

Recebemos uma solicitação para redefinir sua senha no AlertaMed.

Seu código de recuperação é: ${code}

Este código expira em 10 minutos.

Se você não solicitou a recuperação, ignore esta mensagem.

Equipe AlertaMed`,
  });
}
