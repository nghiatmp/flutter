export type CreateTaskBody = {
  title?: string;
  description?: string;
  imagePath?: string | null;
};

export type UpdateTaskBody = Partial<CreateTaskBody>;
