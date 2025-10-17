import { Request, Response } from 'express';
import * as Svc from '../services/user.service';

export async function register(req: Request, res: Response) {
  try {
    const data = await Svc.register(req.body);
    res.status(201).json(data);
  } catch (e: any) {
    res.status(409).json({ message: e.message });
  }
}

export async function login(req: Request, res: Response) {
  try {
    const { token, user } = await Svc.login(req.body.email, req.body.password);
    res.json({ token, user });
  } catch (e: any) {
    res.status(401).json({ message: e.message });
  }
}
