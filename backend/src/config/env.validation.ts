import * as Joi from "joi";

export const envValidationSchema = Joi.object({
  NODE_ENV: Joi.string()
    .valid("development", "production", "test")
    .default("development"),
  PORT: Joi.number().default(3000),
  API_TOKEN_SECRET: Joi.string()
    .min(16)
    .when("NODE_ENV", {
      is: "production",
      then: Joi.required(),
      otherwise: Joi.optional(),
    }),
  CORS_ORIGIN: Joi.string().allow("").optional(),
  THROTTLE_TTL_MS: Joi.number().default(60000),
  THROTTLE_LIMIT: Joi.number().default(60),
});
