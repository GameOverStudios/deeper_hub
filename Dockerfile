# Use the official Elixir image
FROM elixir:1.18-alpine AS build

# Install build dependencies
RUN apk add --no-cache build-base git

# Set build ENV
ENV MIX_ENV=prod

# Install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Create app directory
WORKDIR /app

# Copy mix files
COPY mix.exs mix.lock ./

# Install dependencies
RUN mix deps.get --only prod
RUN mix deps.compile

# Copy source code
COPY . .

# Compile the project
RUN mix compile

# Build release
RUN mix release

# Start a new build stage for the runtime image
FROM alpine:3.18 AS runtime

# Install runtime dependencies
RUN apk add --no-cache openssl ncurses-libs

# Create app user
RUN addgroup -g 1000 app && \
    adduser -u 1000 -G app -s /bin/sh -D app

# Create app directory
WORKDIR /app

# Copy the release from build stage
COPY --from=build --chown=app:app /app/_build/prod/rel/deeper_hub ./

# Create directories for data and logs
RUN mkdir -p /app/data /app/logs && \
    chown -R app:app /app

# Switch to app user
USER app

# Expose port
EXPOSE 4000

# Set environment variables
ENV HOME=/app
ENV MIX_ENV=prod
ENV DATABASE_PATH=/app/data/deeper_hub.db
ENV LOG_FILE_PATH=/app/logs/app.log

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD /app/bin/deeper_hub rpc "DeeperHub.health_check()" || exit 1

# Start the application
CMD ["/app/bin/deeper_hub", "start"]