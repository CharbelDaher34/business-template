import { z } from "zod"

// Same rule as the backend (USERNAME_PATTERN in backend/app/models/user.py).
export const usernameSchema = z
  .string()
  .min(3, { message: "Username must be at least 3 characters" })
  .max(50, { message: "Username must be at most 50 characters" })
  .regex(/^[A-Za-z0-9._-]+$/, {
    message: "Use only letters, numbers, dots, dashes and underscores",
  })
