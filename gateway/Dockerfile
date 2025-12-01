# The Dockerfile for the production environment

#################
# Base stage
#################
FROM node:25.2-alpine3.22 AS base

# Working directory 
WORKDIR /app

# Non-root user for better security
RUN addgroup -g 1001 -S nodeprod && \
    adduser -S nodeprod -u 1001 -G nodeprod && \
    chown -R nodeprod:nodeprod /app


#################
# Dependency installation stage
#################
FROM base AS dependencies

# Set proper ownership
RUN chown -R nodeprod:nodeprod /app

# Copying package files
COPY --chown=nodeprod:nodeprod package*.json ./

# Installing production dependencies
RUN npm install --omit=dev --no-audit --no-fund

# Clean cache
RUN npm cache clean --force

#################
# Production stage
#################
FROM node:25.2-alpine3.22 AS production

# Setting ENV variable
ENV NODE_ENV=production

# Working directory 
WORKDIR /app

# Non-root user for better security
RUN addgroup -g 1001 -S nodeprod && \
    adduser -S nodeprod -u 1001 -G nodeprod && \
    chown -R nodeprod:nodeprod /app


# Copy production dependencies
COPY --from=dependencies --chown=nodeprod:nodeprod /app/node_modules ./node_modules
COPY --from=dependencies --chown=nodeprod:nodeprod /app/package*.json ./
# Copy code from repo
COPY --chown=nodeprod:nodeprod /src ./src

# Switch to non-root user for security
USER nodeprod

# Expose port
EXPOSE 5921

CMD [ "npm", "run", "start" ]