import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
  Logger,
} from "@nestjs/common";
import { Request, Response } from "express";

@Catch()
export class HttpExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger("ExceptionFilter");

  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const request = ctx.getRequest<Request>();

    const isHttpException = exception instanceof HttpException;
    const status = isHttpException
      ? exception.getStatus()
      : HttpStatus.INTERNAL_SERVER_ERROR;

    const body = this.buildBody(status, isHttpException ? exception : null);

    if (!isHttpException) {
      this.logger.error(
        `${request.method} ${request.url} -> Unhandled exception`,
        exception instanceof Error ? exception.stack : String(exception),
      );
    }

    response.status(status).json(body);
  }

  private buildBody(status: number, exception: HttpException | null) {
    const timestamp = new Date().toISOString();

    if (!exception) {
      return {
        success: false,
        statusCode: status,
        message: "Đã xảy ra lỗi, vui lòng thử lại sau",
        timestamp,
      };
    }

    const payload = exception.getResponse();
    if (typeof payload === "string") {
      return { success: false, statusCode: status, message: payload, timestamp };
    }
    return { success: false, statusCode: status, ...payload, timestamp };
  }
}
