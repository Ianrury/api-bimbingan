import { createQueue } from "./bull";

export const USER_REGISTERED_Q = "user-registered";
export const userRegisteredQueue = createQueue(USER_REGISTERED_Q);

export async function enqueueUserRegistered(userId: number) {
  await userRegisteredQueue.add("send-verify-email", { userId }, { attempts: 3, backoff: 60000 });
}
