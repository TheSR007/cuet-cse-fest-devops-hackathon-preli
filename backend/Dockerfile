# Build Stage
FROM node:20-alpine AS builder

WORKDIR /app

# Copy dependency files
COPY package*.json ./

# Install all dependencies
RUN npm install && npm cache clean --force

# Copy source code and build
COPY . .

# ENFORCE TYPE CHECKING
RUN npm run type-check

# Build the application
RUN npm run build

# Runtime Stage
FROM node:20-alpine AS runtime

WORKDIR /app

# Copy dependency files & install only production dependencies
COPY package*.json ./
RUN npm install --omit=dev && npm cache clean --force

# Copy built application from builder stage
COPY --from=builder /app/dist ./dist

# Create non-root user for security
RUN addgroup -g 1001 -S nodeprod && \
    adduser -S nodeprod -u 1001

RUN chown -R nodeprod:nodeprod /app

USER nodeprod

# Expose backend port (internal to Docker network only)
EXPOSE 3847

# Start application
CMD ["npm", "run", "start"]