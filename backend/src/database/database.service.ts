import { Injectable, OnModuleInit } from "@nestjs/common";
import { mkdir, readFile, writeFile } from "node:fs/promises";
import { dirname, join } from "node:path";
import { DatabaseData } from "./database.types";

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
    } catch {
      await this.save(this.createEmptyData());
    }
  }

  private createEmptyData(): DatabaseData {
    return {
      users: [],
      tasks: [],
      posts: [],
    };
  }
}
