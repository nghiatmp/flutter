import { Body, Controller, Get, Post, Req, UseGuards } from "@nestjs/common";
import { AuthenticatedRequest } from "../common/authenticated-request";
import { AuthGuard } from "./auth.guard";
import { AuthService } from "./auth.service";
import { LoginBody, RegisterBody } from "./auth.types";

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
}
