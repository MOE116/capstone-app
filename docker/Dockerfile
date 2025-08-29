# =========================
# Stage 1: Build & Install deps
# =========================
FROM node:18-alpine AS builder

WORKDIR /app

# Copy package files from the app folder
COPY app/package*.json ./

# Install only production dependencies
RUN npm install --production

# Copy the application source
COPY app/ ./

# =========================
# Stage 2: Runtime (minimal, secure, non-root)
# =========================
FROM node:18-alpine

WORKDIR /app

# Create a non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Copy built app from builder
COPY --from=builder /app /app

# Use non-root user
USER appuser

# Expose app port
EXPOSE 8080

# Run the app
CMD ["node", "server.js"]
