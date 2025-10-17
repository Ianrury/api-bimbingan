import nodemailer from "nodemailer";
import { env } from "../config/env";

const transporter = nodemailer.createTransport({
  host: env.SMTP_HOST,
  port: env.SMTP_PORT,
  secure: env.SMTP_SECURE,
  auth: { user: env.SMTP_USER, pass: env.SMTP_PASS },
});

export async function sendVerificationEmail(toEmail: string, verifyUrl: string) {
  const html = `
    <p>Halo,</p>
    <p>Silakan verifikasi email kamu dengan klik tautan di bawah ini:</p>
    <p><a href="${verifyUrl}" target="_blank" rel="noopener">${verifyUrl}</a></p>
    <p>Link berlaku ${env.EMAIL_VERIFY_EXPIRES_HOURS} jam.</p>
  `;
  await transporter.sendMail({
    from: `"${env.SMTP_FROM_NAME}" <${env.SMTP_FROM_EMAIL}>`,
    to: toEmail,
    subject: "Verifikasi Email Akun",
    html,
  });
}
