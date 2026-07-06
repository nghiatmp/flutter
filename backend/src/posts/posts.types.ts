export type CreatePostBody = {
  title?: string;
  body?: string;
};

export type UpdatePostBody = Partial<CreatePostBody>;
