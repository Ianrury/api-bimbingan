import { Router } from 'express';
import authRoutes from './auth.routes';
import userRoutes from './user.routes';

const r = Router();
r.use('/auth', authRoutes);
r.use('/users', userRoutes);
export default r;
