import {
  CallHandler,
  ExecutionContext,
  Injectable,
  Logger,
  NestInterceptor,
} from "@nestjs/common";
import { Request, Response } from "express";
import { Observable } from "rxjs";
import { tap } from "rxjs/operators";

@Injectable()
export class LoggingInterceptor implements NestInterceptor {
  private readonly logger = new Logger("HTTP");

  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    const request = context.switchToHttp().getRequest<Request>();
    const response = context.switchToHttp().getResponse<Response>();
    const { method, originalUrl } = request;
    const start = Date.now();

    return next.handle().pipe(
      tap({
        next: () => this.log(method, originalUrl, response.statusCode, start),
        error: (error) =>
          this.log(
            method,
            originalUrl,
            error?.status ?? response.statusCode ?? 500,
            start,
          ),
      }),
    );
  }

  private log(method: string, url: string, statusCode: number, start: number) {
    this.logger.log(`${method} ${url} ${statusCode} - ${Date.now() - start}ms`);
  }
}
