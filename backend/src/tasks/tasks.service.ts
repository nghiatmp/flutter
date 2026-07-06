import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from "@nestjs/common";
import { randomUUID } from "node:crypto";
import { DatabaseService } from "../database/database.service";
import { TaskRecord } from "../database/database.types";
import { CreateTaskBody, UpdateTaskBody } from "./tasks.types";

@Injectable()
export class TasksService {
  constructor(private readonly database: DatabaseService) {}

  findAll(userId: string): TaskRecord[] {
    return this.database.snapshot.tasks
      .filter((task) => task.userId === userId)
      .sort((a, b) => b.createdAt.localeCompare(a.createdAt));
  }

  findOne(userId: string, taskId: string): TaskRecord {
    const task = this.database.snapshot.tasks.find(
      (item) => item.userId === userId && item.id === taskId,
    );
    if (!task) throw new NotFoundException("Không tìm thấy công việc");
    return task;
  }

  async create(userId: string, body: CreateTaskBody): Promise<TaskRecord> {
    const title = body.title?.trim();
    const description = body.description?.trim();

    if (!title) throw new BadRequestException("Tiêu đề là bắt buộc");
    if (!description) throw new BadRequestException("Mô tả là bắt buộc");

    const now = new Date().toISOString();
    const task: TaskRecord = {
      id: randomUUID(),
      userId,
      title,
      description,
      imagePath: body.imagePath ?? null,
      createdAt: now,
      updatedAt: now,
    };

    const data = this.database.snapshot;
    await this.database.save({
      ...data,
      tasks: [task, ...data.tasks],
    });

    return task;
  }

  async update(
    userId: string,
    taskId: string,
    body: UpdateTaskBody,
  ): Promise<TaskRecord> {
    const current = this.findOne(userId, taskId);
    const updated: TaskRecord = {
      ...current,
      title: body.title?.trim() ?? current.title,
      description: body.description?.trim() ?? current.description,
      imagePath:
        body.imagePath === undefined ? current.imagePath : body.imagePath,
      updatedAt: new Date().toISOString(),
    };

    if (!updated.title) throw new BadRequestException("Tiêu đề là bắt buộc");
    if (!updated.description)
      throw new BadRequestException("Mô tả là bắt buộc");

    const data = this.database.snapshot;
    await this.database.save({
      ...data,
      tasks: data.tasks.map((task) =>
        task.id === taskId && task.userId === userId ? updated : task,
      ),
    });

    return updated;
  }

  async remove(userId: string, taskId: string): Promise<{ deleted: true }> {
    this.findOne(userId, taskId);

    const data = this.database.snapshot;
    await this.database.save({
      ...data,
      tasks: data.tasks.filter(
        (task) => task.id !== taskId || task.userId !== userId,
      ),
    });

    return { deleted: true };
  }
}
