import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Req,
  UseGuards,
} from "@nestjs/common";
import { AuthGuard } from "../auth/auth.guard";
import { AuthenticatedRequest } from "../common/authenticated-request";
import { PostsService } from "./posts.service";
import { CreatePostBody, UpdatePostBody } from "./posts.types";

@Controller("posts")
export class PostsController {
  constructor(private readonly postsService: PostsService) {}

  @Get()
  findAll() {
    return this.postsService.findAll();
  }

  @Get(":id")
  findOne(@Param("id") id: string) {
    return this.postsService.findOne(id);
  }

  @Post()
  @UseGuards(AuthGuard)
  create(@Req() request: AuthenticatedRequest, @Body() body: CreatePostBody) {
    return this.postsService.create(request.user.id, body);
  }

  @Patch(":id")
  @UseGuards(AuthGuard)
  update(
    @Req() request: AuthenticatedRequest,
    @Param("id") id: string,
    @Body() body: UpdatePostBody,
  ) {
    return this.postsService.update(request.user.id, id, body);
  }

  @Delete(":id")
  @UseGuards(AuthGuard)
  remove(@Req() request: AuthenticatedRequest, @Param("id") id: string) {
    return this.postsService.remove(request.user.id, id);
  }
}
