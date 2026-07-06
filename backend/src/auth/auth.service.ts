import {
  BadRequestException,
  ConflictException,
  Injectable,
  UnauthorizedException,
} from "@nestjs/common";
import { randomUUID } from "node:crypto";
import { CryptoService } from "../common/crypto.service";
import { DatabaseService } from "../database/database.service";
import { UserRecord } from "../database/database.types";
import {
  AuthResponse,
  LoginBody,
  PublicUser,
  RegisterBody,
} from "./auth.types";

@Injectable()
export class AuthService {
  constructor(
    private readonly database: DatabaseService,
    private readonly crypto: CryptoService,
  ) {}

  async register(body: RegisterBody): Promise<AuthResponse> {
    const email = this.normalizeEmail(body.email);
    const password = body.password?.trim();

    if (!body.fullName?.trim())
      throw new BadRequestException("Họ tên là bắt buộc");
    if (!email) throw new BadRequestException("Email không hợp lệ");
    if (!password || password.length < 6) {
      throw new BadRequestException("Mật khẩu phải có ít nhất 6 ký tự");
    }
    if (body.acceptedTerms !== true) {
      throw new BadRequestException("Bạn cần đồng ý điều khoản");
    }

    const data = this.database.snapshot;
    const existed = data.users.some((user) => user.email === email);
    if (existed) throw new ConflictException("Email đã được đăng ký");

    const now = new Date().toISOString();
    const user: UserRecord = {
      id: randomUUID(),
      fullName: body.fullName.trim(),
      email,
      passwordHash: this.crypto.hashPassword(password),
      gender: body.gender?.trim() ?? "",
      hobbies: Array.isArray(body.hobbies) ? body.hobbies : [],
      birthDate: body.birthDate ?? "",
      city: body.city?.trim() ?? "",
      acceptedTerms: true,
      createdAt: now,
      updatedAt: now,
    };

    await this.database.save({
      ...data,
      users: [...data.users, user],
    });

    return this.createAuthResponse(user);
  }

  async login(body: LoginBody): Promise<AuthResponse> {
    const email = this.normalizeEmail(body.email);
    const password = body.password ?? "";

    const user = this.database.snapshot.users.find(
      (item) => item.email === email,
    );
    if (!user || !this.crypto.verifyPassword(password, user.passwordHash)) {
      throw new UnauthorizedException("Email hoặc mật khẩu không đúng");
    }

    return this.createAuthResponse(user);
  }

  findPublicUserById(userId: string): PublicUser | null {
    const user = this.database.snapshot.users.find(
      (item) => item.id === userId,
    );
    return user ? this.toPublicUser(user) : null;
  }

  toPublicUser(user: UserRecord): PublicUser {
    const { passwordHash: _passwordHash, ...publicUser } = user;
    return publicUser;
  }

  private createAuthResponse(user: UserRecord): AuthResponse {
    const publicUser = this.toPublicUser(user);
    return {
      user: publicUser,
      accessToken: this.crypto.signToken({
        sub: user.id,
        email: user.email,
        issuedAt: new Date().toISOString(),
      }),
    };
  }

  private normalizeEmail(email?: string): string {
    return email?.trim().toLowerCase() ?? "";
  }
}
