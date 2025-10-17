import { Router } from 'express';
import { validate } from '../middlewares/validate.middleware';
import { loginSchema, registerSchema } from '../schemas/auth.schema';
import * as Auth from '../controllers/auth.controller';

const r = Router();
r.post('/register', validate(registerSchema), Auth.register);
r.post('/login', validate(loginSchema), Auth.login);
export default r;
