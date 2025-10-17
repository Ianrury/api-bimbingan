import { Router } from 'express';
import { authGuard } from '../middlewares/auth.middleware';
import * as User from '../controllers/user.controller';

const r = Router();
r.get('/me', authGuard, User.me);
export default r;
