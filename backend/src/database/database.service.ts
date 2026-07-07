import { Injectable, OnModuleInit } from "@nestjs/common";
import { mkdir, readFile, writeFile } from "node:fs/promises";
import { dirname, join } from "node:path";
import { DatabaseData, PostRecord } from "./database.types";

@Injectable()
export class DatabaseService implements OnModuleInit {
  private readonly dbPath = join(process.cwd(), "data", "db.json");
  private data: DatabaseData = this.createEmptyData();

  async onModuleInit() {
    await this.load();
  }

  get snapshot(): DatabaseData {
    return this.data;
  }

  async save(nextData: DatabaseData) {
    this.data = nextData;
    await mkdir(dirname(this.dbPath), { recursive: true });
    await writeFile(this.dbPath, JSON.stringify(this.data, null, 2));
  }

  private async load() {
    try {
      const raw = await readFile(this.dbPath, "utf8");
      this.data = JSON.parse(raw) as DatabaseData;
      if (this.data.posts.length === 0) {
        await this.save({
          ...this.data,
          posts: this.createDemoPosts(),
        });
      }
    } catch {
      await this.save(this.createEmptyData());
    }
  }

  private createEmptyData(): DatabaseData {
    return {
      users: [],
      posts: this.createDemoPosts(),
    };
  }

  private createDemoPosts(): PostRecord[] {
    const now = new Date().toISOString();

    return [
      {
        id: "demo-post-1",
        userId: "system",
        title: "Kết nối Flutter với NestJS",
        body: "Bài viết demo đầu tiên từ backend. Dữ liệu này giúp màn Posts có nội dung ngay khi mở app.",
        imagePath: null,
        createdAt: now,
        updatedAt: now,
      },
      {
        id: "demo-post-2",
        userId: "system",
        title: "Tạo bài viết kèm ảnh",
        body: "Form tạo post hỗ trợ chọn ảnh trên thiết bị và lưu imagePath vào backend.",
        imagePath: null,
        createdAt: now,
        updatedAt: now,
      },
      {
        id: "demo-post-3",
        userId: "system",
        title: "Settings có theme và ngôn ngữ",
        body: "Màn Settings đã lưu theme mode và language code để app nhớ lựa chọn sau khi mở lại.",
        imagePath: null,
        createdAt: now,
        updatedAt: now,
      },
    ];
  }
}
