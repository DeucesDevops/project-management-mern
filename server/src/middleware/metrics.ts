import { Registry, collectDefaultMetrics, Counter, Histogram, Gauge } from 'prom-client';
import mongoose from 'mongoose';
import type { Request, Response, NextFunction } from 'express';

const register = new Registry();

collectDefaultMetrics({ register });

const httpRequestsTotal = new Counter({
    name: 'http_requests_total',
    help: 'Total number of HTTP requests',
    labelNames: ['method', 'route', 'status_code'],
    registers: [register],
});

const httpRequestDuration = new Histogram({
    name: 'http_request_duration_seconds',
    help: 'Duration of HTTP requests in seconds',
    labelNames: ['method', 'route'],
    buckets: [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5],
    registers: [register],
});

const mongoConnectionState = new Gauge({
    name: 'mongodb_connection_state',
    help: 'MongoDB connection state (1 = connected)',
    registers: [register],
    collect() {
        this.set(mongoose.connection.readyState);
    },
});

// Keep linter happy — gauge is used via collect() above
void mongoConnectionState;

export const metricsMiddleware = (req: Request, res: Response, next: NextFunction): void => {
    const end = httpRequestDuration.startTimer({ method: req.method, route: req.path });
    res.on('finish', () => {
        httpRequestsTotal.inc({
            method: req.method,
            route: req.path,
            status_code: String(res.statusCode),
        });
        end();
    });
    next();
};

export const getMetrics = async (_req: Request, res: Response): Promise<void> => {
    res.set('Content-Type', register.contentType);
    res.end(await register.metrics());
};
