import { Module } from "@nestjs/common";
import { CryptoService } from "../common/crypto.service";
import { AuthController } from "./auth.controller";
import { AuthGuard } from "./auth.guard";
import { AuthService } from "./auth.service";

@Module({
  controllers: [AuthController],
  providers: [AuthService, AuthGuard, CryptoService],
  exports: [AuthService, AuthGuard, CryptoService],
})
export class AuthModule {}
