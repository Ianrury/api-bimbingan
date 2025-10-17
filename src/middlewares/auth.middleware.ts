import { Request, Response, NextFunction } from 'express';
import { verifyJwt } from '../utils/jwt';

export const authGuard = (req: Request, res: Response, next: NextFunction) => {
  const h = req.headers.authorization;
  const token = h?.startsWith('Bearer ') ? h.slice(7) : null;
  if (!token) return res.status(401).json({ message: 'Unauthorized' });
  try {
    (req as any).user = verifyJwt<{ sub: string; role: string }>(token);
    next();
  } catch {
    return res.status(401).json({ message: 'Invalid token' });
  }
};
