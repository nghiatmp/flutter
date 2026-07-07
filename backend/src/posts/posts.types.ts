export type CreatePostBody = {
  title?: string;
  body?: string;
  imagePath?: string | null;
};

export type UpdatePostBody = Partial<CreatePostBody>;
