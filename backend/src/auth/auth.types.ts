import {
  Equals,
  IsArray,
  IsBoolean,
  IsEmail,
  IsOptional,
  IsString,
  MinLength,
} from "class-validator";
import { UserRecord } from "../database/database.types";

export class RegisterBody {
  @IsString()
  @MinLength(1)
  fullName: string;

  @IsEmail()
  email: string;

  @IsString()
  @MinLength(6)
  password: string;

  @IsOptional()
  @IsString()
  gender?: string;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  hobbies?: string[];

  @IsOptional()
  @IsString()
  birthDate?: string;

  @IsOptional()
  @IsString()
  city?: string;

  @IsBoolean()
  @Equals(true)
  acceptedTerms: boolean;
}

export class LoginBody {
  @IsEmail()
  email: string;

  @IsString()
  @MinLength(1)
  password: string;
}

export type PublicUser = Omit<UserRecord, "passwordHash">;

export type AuthResponse = {
  user: PublicUser;
  accessToken: string;
};
