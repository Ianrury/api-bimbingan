import 'dotenv/config';


export const env = {
    port: Number(process.env.PORT ?? 8000),
    dbURL: process.env.DATABASE_URL!,
    jwtSecret: process.env.JWT_SECRET ?? "secret",
    jwtExpires: process.env.JWT_EXPIRES
}