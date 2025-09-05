import { get } from 'mongoose';
import { getEnv } from '../utils/get-env';

const appConfig = () => ({
    NODE_ENV: getEnv('NODE_ENV', 'development'),
    PORT: getEnv('PORT', '5000'),
    BASE_PATH: getEnv('BASE_PATH', '/api'),
    MONGODB_URI: getEnv('MONGODB_URI',''),

    SESSION_SECRET: getEnv('SESSION_SECRET',''),
    SESSION_EX_IN: getEnv('SESSION_EX_IN',''), // 1 day in milliseconds

    GOOGLE_CLIENT_ID: getEnv('GOOGLE_CLIENT_ID',''),
    GOOGLE_CLIENT_SECRET: getEnv('GOOGLE_CLIENT_SECRET',''),
    GOOGLE_CALLBACK_URL: getEnv('GOOGLE_CALLBACK_URL',''),

    FRONTEND_URL: getEnv('FRONTEND_URL','localhost'),
    FRONTEND_GOOGLE_CALLBACK_URL: getEnv('FRONTEND_GOOGLE_CALLBACK_URL',''),
})

export const config = appConfig();

