# ==============================================================
# MicroLedger - Multi-Stage Production Dockerfile
# ==============================================================

# Stage 1: Build React Frontend
FROM node:20-alpine AS frontend-builder
WORKDIR /app/Frontend
COPY Frontend/package*.json ./
RUN npm ci
COPY Frontend/ ./
RUN npm run build

# Stage 2: Production Server Runner
FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
ENV PORT=5000

# Install Backend dependencies
COPY Backend/package*.json ./Backend/
RUN cd Backend && npm ci --omit=dev

# Copy backend source code & Database scripts
COPY Backend/ ./Backend/
COPY Database/ ./Database/
COPY scripts/ ./scripts/
COPY package.json ./

# Copy built frontend assets from stage 1
COPY --from=frontend-builder /app/Frontend/dist ./Frontend/dist

EXPOSE 5000

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:5000/health || exit 1

CMD ["node", "Backend/server.js"]
