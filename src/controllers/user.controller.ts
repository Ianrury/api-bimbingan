import { Request, Response } from 'express';

export function me(req: Request, res: Response) {
  const user = (req as any).user;
  res.json({ user });
}
