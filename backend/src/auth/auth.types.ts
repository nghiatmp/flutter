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

/// Không có field email ở đây — endpoint update profile không cho đổi email.
export class UpdateProfileBody {
  @IsString()
  @MinLength(1)
  fullName: string;

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
}

export class ChangePasswordBody {
  @IsString()
  @MinLength(1)
  currentPassword: string;

  @IsString()
  @MinLength(6)
  newPassword: string;
}

export type PublicUser = Omit<UserRecord, "passwordHash">;

export type AuthResponse = {
  user: PublicUser;
  accessToken: string;
};
