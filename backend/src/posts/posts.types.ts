import { IsOptional, IsString, MinLength } from "class-validator";

export class CreatePostBody {
  @IsString()
  @MinLength(1)
  title: string;

  @IsString()
  @MinLength(1)
  body: string;

  @IsOptional()
  @IsString()
  imagePath?: string | null;
}

export class UpdatePostBody {
  @IsOptional()
  @IsString()
  @MinLength(1)
  title?: string;

  @IsOptional()
  @IsString()
  @MinLength(1)
  body?: string;

  @IsOptional()
  @IsString()
  imagePath?: string | null;
}
