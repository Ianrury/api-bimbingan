import * as UserRepo from '../repositories/user.repo';
import { hash, compare } from '../utils/password';
import { signJwt } from '../utils/jwt';

export async function register(input: { email: string; name: string; password: string; role?: any }) {
  const exists = await UserRepo.findByEmail(input.email);
  if (exists) throw new Error('Email already in use');
  const user = await UserRepo.create({ ...input, password: await hash(input.password) });
  return user;
}

export async function login(email: string, password: string) {
  const user = await UserRepo.findByEmail(email);
  if (!user) throw new Error('Invalid credentials');
  const ok = await compare(password, user.password);
  if (!ok) throw new Error('Invalid credentials');
  const token = signJwt({ sub: user.id, role: user.role });
  return { token, user: { id: user.id, email: user.email, name: user.name, role: user.role } };
}
