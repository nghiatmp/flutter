import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from "@nestjs/common";
import { randomUUID } from "node:crypto";
import { DatabaseService } from "../database/database.service";
import { PostRecord } from "../database/database.types";
import { CreatePostBody, UpdatePostBody } from "./posts.types";

@Injectable()
export class PostsService {
  constructor(private readonly database: DatabaseService) {}

  findAll(): PostRecord[] {
    return this.database.snapshot.posts.sort((a, b) =>
      b.createdAt.localeCompare(a.createdAt),
    );
  }

  findOne(postId: string): PostRecord {
    const post = this.database.snapshot.posts.find(
      (item) => item.id === postId,
    );
    if (!post) throw new NotFoundException("Không tìm thấy bài viết");
    return post;
  }

  async create(userId: string, body: CreatePostBody): Promise<PostRecord> {
    const title = body.title?.trim();
    const content = body.body?.trim();

    if (!title) throw new BadRequestException("Tiêu đề là bắt buộc");
    if (!content) throw new BadRequestException("Nội dung là bắt buộc");

    const now = new Date().toISOString();
    const post: PostRecord = {
      id: randomUUID(),
      userId,
      title,
      body: content,
      imagePath: body.imagePath ?? null,
      createdAt: now,
      updatedAt: now,
    };

    const data = this.database.snapshot;
    await this.database.save({
      ...data,
      posts: [post, ...data.posts],
    });

    return post;
  }

  async update(
    userId: string,
    postId: string,
    body: UpdatePostBody,
  ): Promise<PostRecord> {
    const current = this.findOwnedPost(userId, postId);
    const updated: PostRecord = {
      ...current,
      title: body.title?.trim() ?? current.title,
      body: body.body?.trim() ?? current.body,
      imagePath:
        body.imagePath === undefined ? current.imagePath : body.imagePath,
      updatedAt: new Date().toISOString(),
    };

    if (!updated.title) throw new BadRequestException("Tiêu đề là bắt buộc");
    if (!updated.body) throw new BadRequestException("Nội dung là bắt buộc");

    const data = this.database.snapshot;
    await this.database.save({
      ...data,
      posts: data.posts.map((post) => (post.id === postId ? updated : post)),
    });

    return updated;
  }

  async remove(userId: string, postId: string): Promise<{ deleted: true }> {
    this.findOwnedPost(userId, postId);

    const data = this.database.snapshot;
    await this.database.save({
      ...data,
      posts: data.posts.filter((post) => post.id !== postId),
    });

    return { deleted: true };
  }

  private findOwnedPost(userId: string, postId: string): PostRecord {
    const post = this.findOne(postId);
    if (post.userId !== userId) {
      throw new ForbiddenException("Bạn không có quyền sửa bài viết này");
    }
    return post;
  }
}
