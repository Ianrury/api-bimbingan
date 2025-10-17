import { email, z } from 'zod';

export const registerSchema = z.object({
    body : z.object({
        email: z.string().email(),
        name: z.string().min(2).max(100),
        password: z.string().min(6),
        role: z.enum(['ADMIN','DOSEN','MAHASISWA','USER']).default("ADMIN").optional()
    })
})

export const loginSchema = z.object({
    body : z.object({
        email: z.string().email(),
        password: z.string().min(8),
    })
})

export type RegisterInput = z.infer<typeof registerSchema>['body'];
export type LoginInput = z.infer<typeof loginSchema>['body'];