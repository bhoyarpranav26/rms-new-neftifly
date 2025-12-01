# Use an official Node runtime as the base image
FROM node:18-alpine AS base

# Create app directory
WORKDIR /usr/src/app

# Install production dependencies only (use package-lock if present)
COPY package*.json ./
RUN npm ci --only=production

# Copy source
COPY . .

# Use non-root user for safety
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

# Expose the port your app listens on
EXPOSE 8080

# Production environment
ENV NODE_ENV=production

# Start the app
CMD ["node", "index.js"]

