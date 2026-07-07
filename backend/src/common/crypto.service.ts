import { Injectable } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import {
  createHmac,
  randomBytes,
  scryptSync,
  timingSafeEqual,
} from "node:crypto";

@Injectable()
export class CryptoService {
  private readonly tokenSecret: string;

  constructor(config: ConfigService) {
    this.tokenSecret =
      config.get<string>("API_TOKEN_SECRET") ?? "study-flutter-dev-secret";
  }

  hashPassword(password: string): string {
    const salt = randomBytes(16).toString("hex");
    const hash = scryptSync(password, salt, 64).toString("hex");
    return `${salt}:${hash}`;
  }

  verifyPassword(password: string, storedHash: string): boolean {
    const [salt, hash] = storedHash.split(":");
    if (!salt || !hash) return false;

    const candidate = scryptSync(password, salt, 64);
    const original = Buffer.from(hash, "hex");
    return (
      candidate.length === original.length &&
      timingSafeEqual(candidate, original)
    );
  }

  signToken(payload: Record<string, unknown>): string {
    const body = Buffer.from(JSON.stringify(payload)).toString("base64url");
    const signature = this.sign(body);
    return `${body}.${signature}`;
  }

  verifyToken<T extends Record<string, unknown>>(token: string): T | null {
    const [body, signature] = token.split(".");
    if (!body || !signature || this.sign(body) !== signature) return null;

    try {
      return JSON.parse(Buffer.from(body, "base64url").toString("utf8")) as T;
    } catch {
      return null;
    }
  }

  private sign(body: string): string {
    return createHmac("sha256", this.tokenSecret)
      .update(body)
      .digest("base64url");
  }
}
