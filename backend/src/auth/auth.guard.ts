import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from "@nestjs/common";
import { Request } from "express";
import { CryptoService } from "../common/crypto.service";
import { AuthenticatedRequest } from "../common/authenticated-request";
import { AuthService } from "./auth.service";

type TokenPayload = {
  sub?: string;
};

@Injectable()
export class AuthGuard implements CanActivate {
  constructor(
    private readonly authService: AuthService,
    private readonly crypto: CryptoService,
  ) {}

  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest<AuthenticatedRequest>();
    const token = this.getBearerToken(request);
    const payload = token ? this.crypto.verifyToken<TokenPayload>(token) : null;
    const user = payload?.sub
      ? this.authService.findPublicUserById(payload.sub)
      : null;

    if (!user) throw new UnauthorizedException("Bạn cần đăng nhập");

    request.user = user;
    return true;
  }

  private getBearerToken(request: Request): string | null {
    const authorization = request.headers.authorization;
    if (!authorization?.startsWith("Bearer ")) return null;
    return authorization.slice("Bearer ".length).trim();
  }
}
