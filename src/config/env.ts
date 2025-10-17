import 'dotenv/config';


export const env = {
    port: Number(process.env.PORT ?? 8000),
    dbURL: process.env.DATABASE_URL!,
    jwtSecret: process.env.JWT_SECRET ?? "secret",
    jwtExpires: process.env.JWT_EXPIRES,

    REDIS_HOST: process.env.REDIS_HOST || "127.0.0.1",
    REDIS_PORT: +(process.env.REDIS_PORT || 6379),
    REDIS_PASSWORD: process.env.REDIS_PASSWORD || undefined,

    SMTP_HOST: process.env.SMTP_HOST!,
    SMTP_PORT: +(process.env.SMTP_PORT || 587),
    SMTP_SECURE: process.env.SMTP_SECURE === "true",
    SMTP_USER: process.env.SMTP_USER!,
    SMTP_PASS: process.env.SMTP_PASS!,
    SMTP_FROM_NAME: process.env.SMTP_FROM_NAME || "Bimbing",
    SMTP_FROM_EMAIL: process.env.SMTP_FROM_EMAIL || "no-reply@bimbing.local",

    APP_URL: process.env.APP_URL || "http://localhost:8000",
    REGISTER_SEND_VERIFY: process.env.REGISTER_SEND_VERIFY !== "false",
    EMAIL_VERIFY_EXPIRES_HOURS: +(process.env.EMAIL_VERIFY_EXPIRES_HOURS || 24),
}