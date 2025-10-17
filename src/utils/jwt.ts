import jwt from 'jsonwebtoken';
import { env } from '../config/env';

export const signJwt = (payload: object) =>
  jwt.sign(
    payload,
    env.jwtSecret as jwt.Secret,
    { expiresIn: env.jwtExpires as jwt.SignOptions['expiresIn'] }
  );

export const verifyJwt = <T>(token: string) =>
  jwt.verify(token, env.jwtSecret as jwt.Secret) as T;
