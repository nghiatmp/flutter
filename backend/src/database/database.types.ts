export type UserRecord = {
  id: string;
  fullName: string;
  email: string;
  passwordHash: string;
  gender: string;
  hobbies: string[];
  birthDate: string;
  city: string;
  acceptedTerms: boolean;
  createdAt: string;
  updatedAt: string;
};

export type PostRecord = {
  id: string;
  userId: string;
  title: string;
  body: string;
  imagePath?: string | null;
  createdAt: string;
  updatedAt: string;
};

export type DatabaseData = {
  users: UserRecord[];
  posts: PostRecord[];
};
