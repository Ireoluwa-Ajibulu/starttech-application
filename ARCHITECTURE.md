# StartTech Application Architecture

# Frontend

The frontend is a React application built with Vite and TypeScript.
It communicates with the backend API.
It is deployed to S3 with CloudFront for global delivery.

# Backend

The backend is a Golang REST API.
It handles authentication, todo management and user management.
It runs inside a Docker container on EC2 instances behind a load balancer.

# Key endpoints

- GET /health - health check
- POST /api/auth/register -This id to register a new user
- POST /api/auth/login - To login
- GET /api/todos - This is to get all todos
- POST /api/todos -  creates a todo
- PUT /api/todos/:id -This updates a todo
- DELETE /api/todos/:id -This deletes a todo

# Environment variables

All environment variables are managed through GitHub secrets.
They are injected at deploy time.
No secrets are stored in the codebase.
