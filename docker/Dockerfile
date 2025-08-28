# =========================
# Stage 1: Build & Install deps
# =========================
FROM node:18-alpine AS builder

WORKDIR /app

# Copy package files and install only production deps
COPY ../app/package.json ../app/package-lock.json* ./
RUN npm install --production

# Copy source code
COPY ../app/server.js .

# =========================
# Stage 2: Runtime (minimal, secure, non-root)
# =========================
FROM node:18-alpine

WORKDIR /app

# Create a non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Copy from builder stage
COPY --from=builder /app /app

# Switch to non-root
USER appuser

# Expose port
EXPOSE 8080

# Run app
CMD ["node", "server.js"]
