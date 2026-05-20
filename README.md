
# StartTech Application

A full-stack todo application with a React frontend and Golang backend.

# Structure

- frontend/ - React application built with Vite and TypeScript
- backend/ - Golang REST API
- scripts/ - deployment and utility scripts
- .github/workflows/ - CI/CD pipelines

# Running locally

# Frontend
cd frontend
npm install
npm run dev

# Backend
cd backend/MuchToDo
go mod download
go run cmd/api/main.go

# Environment variables

# Frontend
VITE_API_URL - URL of the backend API

# Backend
MONGODB_URI - MongoDB connection string
REDIS_URL - Redis connection string
JWT_SECRET - Secret key for JWT tokens

# Deployment

Deployment is handled automatically by GitHub Actions when code is pushed to main.

Frontend changes trigger the frontend pipeline which builds and deploys to S3.
Backend changes trigger the backend pipeline which builds a Docker image, pushes to ECR and deploys to EC2.

# CI/CD Pipelines

frontend-ci-cd.yml - builds and deploys the React frontend to S3
backend-ci-cd.yml - builds and deploys the Golang backend to EC2
