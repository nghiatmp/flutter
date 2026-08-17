import {
  Body,
  Controller,
  Get,
  Patch,
  Post,
  Req,
  UseGuards,
} from "@nestjs/common";
import { AuthenticatedRequest } from "../common/authenticated-request";
import { AuthGuard } from "./auth.guard";
import { AuthService } from "./auth.service";
import {
  ChangePasswordBody,
  LoginBody,
  RegisterBody,
  UpdateProfileBody,
} from "./auth.types";

@Controller("auth")
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post("register")
  register(@Body() body: RegisterBody) {
    return this.authService.register(body);
  }

  @Post("login")
  login(@Body() body: LoginBody) {
    return this.authService.login(body);
  }

  @Get("me")
  @UseGuards(AuthGuard)
  me(@Req() request: AuthenticatedRequest) {
    return request.user;
  }

  /// Không nhận field email — người dùng không được đổi email qua endpoint này.
  @Patch("me")
  @UseGuards(AuthGuard)
  updateProfile(
    @Req() request: AuthenticatedRequest,
    @Body() body: UpdateProfileBody,
  ) {
    return this.authService.updateProfile(request.user.id, body);
  }

  @Post("change-password")
  @UseGuards(AuthGuard)
  async changePassword(
    @Req() request: AuthenticatedRequest,
    @Body() body: ChangePasswordBody,
  ) {
    await this.authService.changePassword(request.user.id, body);
    return { success: true };
  }
}
