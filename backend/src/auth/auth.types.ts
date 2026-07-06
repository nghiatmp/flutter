import { UserRecord } from "../database/database.types";

export type RegisterBody = {
  fullName?: string;
  email?: string;
  password?: string;
  gender?: string;
  hobbies?: string[];
  birthDate?: string;
  city?: string;
  acceptedTerms?: boolean;
};

export type LoginBody = {
  email?: string;
  password?: string;
};

export type PublicUser = Omit<UserRecord, "passwordHash">;

export type AuthResponse = {
  user: PublicUser;
  accessToken: string;
};
