import {
  BadRequestException,
  ConflictException,
  Injectable,
  OnModuleInit,
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

/// Tài khoản demo có sẵn để app Flutter tự điền form login khi mới cài.
/// Đổi ở đây thì nhớ đổi luôn AppConstants.demoUserEmail/Password bên Flutter.
export const DEFAULT_USER_EMAIL = "demo@studyflutter.com";
export const DEFAULT_USER_PASSWORD = "123456";

@Injectable()
export class AuthService implements OnModuleInit {
  constructor(
    private readonly database: DatabaseService,
    private readonly crypto: CryptoService,
  ) {}

  async onModuleInit() {
    await this.seedDefaultUser();
  }

  private async seedDefaultUser() {
    const data = this.database.snapshot;
    if (data.users.some((user) => user.email === DEFAULT_USER_EMAIL)) return;

    const now = new Date().toISOString();
    const defaultUser: UserRecord = {
      id: randomUUID(),
      fullName: "Người dùng demo",
      email: DEFAULT_USER_EMAIL,
      passwordHash: this.crypto.hashPassword(DEFAULT_USER_PASSWORD),
      gender: "",
      hobbies: [],
      birthDate: "",
      city: "",
      acceptedTerms: true,
      createdAt: now,
      updatedAt: now,
    };

    await this.database.save({
      ...data,
      users: [...data.users, defaultUser],
    });
  }

  async register(body: RegisterBody): Promise<AuthResponse> {
    const email = this.normalizeEmail(body.email);
    const password = body.password?.trim();

    if (!body.fullName?.trim())
      throw new BadRequestException("Họ tên là bắt buộc");
    if (!password || password.length < 6) {
      throw new BadRequestException("Mật khẩu phải có ít nhất 6 ký tự");
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
