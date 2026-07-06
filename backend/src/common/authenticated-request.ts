import { Request } from "express";
import { PublicUser } from "../auth/auth.types";

export type AuthenticatedRequest = Request & {
  user: PublicUser;
};
