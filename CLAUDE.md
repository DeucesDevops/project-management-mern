# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Full-stack MERN project management app with TypeScript throughout. Two independent packages under `client/` (React + Vite) and `server/` (Express + MongoDB). Each has its own `node_modules` and must be run separately.

## Commands

### Server (`cd server`)
```bash
npm run dev      # tsx watch src/index.ts (hot reload)
npm run build    # tsc (compile to dist/)
npm start        # node dist/index.js (production)
```

### Client (`cd client`)
```bash
npm run dev      # vite dev server
npm run build    # tsc -b && vite build
npm run lint     # eslint .
npm run preview  # vite preview
```

There is no test framework configured in either package.

## Environment Setup

Copy `server/.env.example` to `server/.env` and fill in values:
```
PORT=5001
MONGO_URI=your_mongodb_connection_string
JWT_SECRET=your_jwt_secret_key
```

**Important port note:** `client/src/services/api.ts` hardcodes `baseURL: 'http://localhost:5002/api'`. The server defaults to port `5001` (or `PORT` from env). Ensure the server `PORT` matches the client's hardcoded base URL, or update `api.ts` accordingly.

## Architecture

### Server (`server/src/`)
- `index.ts` — Express app entry: registers middleware, connects MongoDB, mounts routes
- `config/db.ts` — Mongoose connection
- `middleware/auth.ts` — JWT auth middleware; attaches `req.user` (IUser) to `AuthRequest`
- `models/` — Mongoose schemas: `User`, `Project`, `Task`
- `routes/` — Express routers: `auth`, `projects`, `tasks`, `users`
- `types/index.ts` — Shared TypeScript interfaces (`IUser`, `IProject`, `ITask`, `AuthRequest`)

All routes except auth are protected via the `auth` middleware. Routes use `AuthRequest` (extends `Express.Request` with `user?: IUser`).

### Client (`client/src/`)
- `main.tsx` → `App.tsx` — React 19 app entry
- `context/AuthContext.tsx` — Global auth state; reads/writes `token` and `user` to `localStorage`; exposes `login`, `register`, `logout`, `updateProfile`
- `services/api.ts` — Axios instance with base URL + request interceptor (attaches `Bearer` token) + response interceptor (clears storage and redirects on 401)
- `components/ProtectedRoute.tsx` — Wraps routes that require authentication
- `components/Layout.tsx` — Shell with `Header` + `Sidebar` + `<Outlet />`
- `pages/` — Route-level components: `Dashboard`, `Projects`, `ProjectDetail`, `Tasks`, `Team`, `Settings`, `Seed`

### Data Models

**User**: `name`, `email`, `password` (bcrypt), `role` (`admin|manager|member`), `avatar`

**Project**: `title`, `description`, `status` (`active|completed|on-hold`), `priority` (`low|medium|high|critical`), `owner` (User ref), `members` (User[] ref), `deadline`

**Task**: `title`, `description`, `status` (`todo|in-progress|review|done`), `priority` (`low|medium|high|critical`), `project` (Project ref), `assignee` (User ref), `dueDate`

### API Routes
| Method | Path | Description |
|--------|------|-------------|
| POST | `/api/auth/register` | Register (returns JWT) |
| POST | `/api/auth/login` | Login (returns JWT) |
| GET | `/api/auth/me` | Current user |
| PUT | `/api/auth/profile` | Update profile |
| GET/POST | `/api/projects` | List/create projects |
| GET/PUT/DELETE | `/api/projects/:id` | Project CRUD |
| GET | `/api/projects/:id/tasks` | Tasks for a project |
| GET/POST | `/api/tasks` | List/create tasks |
| GET/PUT/DELETE | `/api/tasks/:id` | Task CRUD |
| PATCH | `/api/tasks/:id/status` | Update task status only |
| GET/PUT/DELETE | `/api/users` | User management |
| GET | `/api/health` | Health check |

## Key Conventions

- All shared server types live in `server/src/types/index.ts`
- Route handlers explicitly type `Promise<void>` return and handle errors with `try/catch` returning `{ message, error }` JSON
- Projects are scoped to the authenticated user: fetches only projects where user is `owner` or in `members`
- Tasks are scoped similarly: tasks where user is `assignee` or belongs to user's projects
- Deleting a project cascades to delete all its tasks (`Task.deleteMany({ project: project._id })`)
- Tailwind CSS v4 is used via `@tailwindcss/vite` plugin (no `tailwind.config.js`)
