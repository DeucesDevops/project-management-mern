# Project Management MERN

A full-stack project management application built with the MERN stack (MongoDB, Express, React, Node.js). Manage projects and tasks collaboratively with role-based access control and a modern glassmorphic UI.

## Features

- **Authentication** — JWT-based login/registration with role-based access (Admin, Manager, Member)
- **Project Management** — Create, update, and delete projects with status, priority, deadlines, and team members
- **Task Board** — Kanban-style board with columns: To Do, In Progress, Review, Done
- **Dashboard** — Overview stats for projects and tasks, recent activity widgets
- **Team View** — Browse all registered team members and their roles
- **Profile Settings** — Update name, email, and password

## Tech Stack

| Layer    | Technology                                      |
|----------|-------------------------------------------------|
| Frontend | React 19, TypeScript, Vite, Tailwind CSS, Axios |
| Backend  | Node.js, Express 4, TypeScript                  |
| Database | MongoDB 7 with Mongoose                         |
| Cache    | Redis 7                                         |
| Auth     | JWT (30-day expiry), bcrypt                     |
| DevOps   | Docker, Docker Compose, Nginx                   |

## Project Structure

```
project-management-mern/
├── client/               # React frontend (Vite + TypeScript)
│   ├── src/
│   │   ├── pages/        # Dashboard, Projects, Tasks, Team, Settings, Auth
│   │   ├── components/   # Layout, Sidebar, Header, ProtectedRoute
│   │   ├── context/      # AuthContext
│   │   └── services/     # Axios API client
│   └── Dockerfile
├── server/               # Express backend (TypeScript)
│   ├── src/
│   │   ├── models/       # User, Project, Task (Mongoose)
│   │   ├── routes/       # auth, projects, tasks, users
│   │   ├── middleware/   # JWT auth, metrics
│   │   └── config/       # DB connection, logger
│   └── Dockerfile
└── docker-compose.yml
```

## Getting Started

### Prerequisites

- [Docker](https://docs.docker.com/get-docker/) and Docker Compose
- Or: Node.js 20+ and MongoDB 7+ for local development

### Docker (recommended)

1. Clone the repository:
   ```bash
   git clone <repo-url>
   cd project-management-mern
   ```

2. Create your environment file:
   ```bash
   cp .env.example .env
   ```

3. Edit `.env` and set secure values — especially `JWT_SECRET`:
   ```bash
   # Generate a strong JWT secret
   openssl rand -base64 64
   ```

4. Start all services:
   ```bash
   docker compose up --build
   ```

5. Open [http://localhost](http://localhost) in your browser.

### Local Development

**Server:**
```bash
cd server
cp ../.env.example .env   # adjust MONGO_URI, JWT_SECRET, etc.
npm install
npm run dev               # tsx watch — live reload on port 5001
```

**Client:**
```bash
cd client
cp .env.example .env      # set VITE_API_URL=http://localhost:5001/api
npm install
npm run dev               # Vite dev server on port 5173
```

## Environment Variables

Copy `.env.example` to `.env` in the project root and fill in the values:

| Variable              | Description                              | Default                    |
|-----------------------|------------------------------------------|----------------------------|
| `MONGO_ROOT_USER`     | MongoDB admin username                   | `admin`                    |
| `MONGO_ROOT_PASSWORD` | MongoDB admin password                   | —                          |
| `MONGO_DB`            | Database name                            | `project_management`       |
| `MONGO_PORT`          | MongoDB port                             | `27017`                    |
| `REDIS_PASSWORD`      | Redis password                           | —                          |
| `REDIS_PORT`          | Redis port                               | `6379`                     |
| `JWT_SECRET`          | Secret key for signing JWTs (**required**) | —                        |
| `CLIENT_PORT`         | Port for the Nginx/client container      | `80`                       |

**Client** (`client/.env`):

| Variable        | Description          | Default                       |
|-----------------|----------------------|-------------------------------|
| `VITE_API_URL`  | Backend API base URL | `http://localhost:5001/api`   |

## API Reference

### Auth
| Method | Endpoint              | Description            | Auth |
|--------|-----------------------|------------------------|------|
| POST   | `/api/auth/register`  | Register a new user    | No   |
| POST   | `/api/auth/login`     | Login and get JWT      | No   |
| GET    | `/api/auth/me`        | Get current user       | Yes  |
| PUT    | `/api/auth/profile`   | Update profile         | Yes  |

### Projects
| Method | Endpoint               | Description                          | Auth |
|--------|------------------------|--------------------------------------|------|
| GET    | `/api/projects`        | List user's projects                 | Yes  |
| POST   | `/api/projects`        | Create a project                     | Yes  |
| GET    | `/api/projects/:id`    | Get project details                  | Yes  |
| PUT    | `/api/projects/:id`    | Update a project                     | Yes  |
| DELETE | `/api/projects/:id`    | Delete project (cascades tasks)      | Yes  |
| GET    | `/api/projects/:id/tasks` | Get tasks for a project           | Yes  |

### Tasks
| Method | Endpoint                    | Description             | Auth |
|--------|-----------------------------|-------------------------|------|
| GET    | `/api/tasks`                | List all user's tasks   | Yes  |
| POST   | `/api/tasks`                | Create a task           | Yes  |
| GET    | `/api/tasks/:id`            | Get task details        | Yes  |
| PUT    | `/api/tasks/:id`            | Update a task           | Yes  |
| PATCH  | `/api/tasks/:id/status`     | Update task status only | Yes  |
| DELETE | `/api/tasks/:id`            | Delete a task           | Yes  |

### Users
| Method | Endpoint      | Description          | Auth |
|--------|---------------|----------------------|------|
| GET    | `/api/users`  | List all users       | Yes  |
| GET    | `/api/health` | Health check         | No   |

## Data Models

**User** — `name`, `email`, `password` (hashed), `role` (admin/manager/member), `avatar`

**Project** — `title`, `description`, `status` (active/completed/on-hold), `priority` (low/medium/high/critical), `owner`, `members[]`, `deadline`

**Task** — `title`, `description`, `status` (todo/in-progress/review/done), `priority`, `project`, `assignee`, `dueDate`

## Scripts

| Location | Command         | Description                       |
|----------|-----------------|-----------------------------------|
| `client` | `npm run dev`   | Start Vite dev server             |
| `client` | `npm run build` | TypeScript compile + Vite build   |
| `client` | `npm run lint`  | Run ESLint                        |
| `server` | `npm run dev`   | Start server with live reload     |
| `server` | `npm run build` | Compile TypeScript                |
| `server` | `npm start`     | Run compiled server               |

## License

MIT
