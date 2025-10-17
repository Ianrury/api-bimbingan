import { ZodObject } from 'zod';
import { Request, Response, NextFunction } from 'express';

export const validate = (schema: ZodObject<any>) =>
  (req: Request, res: Response, next: NextFunction) => {
    try {
      schema.parse({ body: req.body, query: req.query, params: req.params });
      next();
    } catch (e: any) {
      return res.status(422).json({ errors: e?.flatten?.() ?? e });
    }
  };
