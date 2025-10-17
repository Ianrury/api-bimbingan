import { Queue, Worker, QueueEvents } from "bullmq";
import IORedis from "ioredis";
import { env } from "../config/env";

export const connection = new IORedis({
  host: env.REDIS_HOST,
  port: env.REDIS_PORT,
  password: env.REDIS_PASSWORD,
  maxRetriesPerRequest: null,
});

export const createQueue = (name: string) =>
  new Queue(name, { connection });

export const createWorker = (name: string, processor: any) =>
  new Worker(name, processor, { connection });

export const createQueueEvents = (name: string) =>
  new QueueEvents(name, { connection });
