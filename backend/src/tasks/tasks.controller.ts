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
import { AuthenticatedRequest } from "../common/authenticated-request";
import { AuthGuard } from "../auth/auth.guard";
import { TasksService } from "./tasks.service";
import { CreateTaskBody, UpdateTaskBody } from "./tasks.types";

@Controller("tasks")
@UseGuards(AuthGuard)
export class TasksController {
  constructor(private readonly tasksService: TasksService) {}

  @Get()
  findAll(@Req() request: AuthenticatedRequest) {
    return this.tasksService.findAll(request.user.id);
  }

  @Get(":id")
  findOne(@Req() request: AuthenticatedRequest, @Param("id") id: string) {
    return this.tasksService.findOne(request.user.id, id);
  }

  @Post()
  create(@Req() request: AuthenticatedRequest, @Body() body: CreateTaskBody) {
    return this.tasksService.create(request.user.id, body);
  }

  @Patch(":id")
  update(
    @Req() request: AuthenticatedRequest,
    @Param("id") id: string,
    @Body() body: UpdateTaskBody,
  ) {
    return this.tasksService.update(request.user.id, id, body);
  }

  @Delete(":id")
  remove(@Req() request: AuthenticatedRequest, @Param("id") id: string) {
    return this.tasksService.remove(request.user.id, id);
  }
}
