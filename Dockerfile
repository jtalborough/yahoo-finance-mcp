# Use a Python image with uv pre-installed
FROM ghcr.io/astral-sh/uv:python3.11-bookworm-slim AS builder

# Install the project into /app
WORKDIR /app

# Enable bytecode compilation
ENV UV_COMPILE_BYTECODE=1

# Copy from the cache instead of linking since it's a mounted volume
ENV UV_LINK_MODE=copy

# Copy project files
COPY pyproject.toml uv.lock ./

# Install the project's dependencies using uv
RUN --mount=type=cache,target=/root/.cache/uv \
    uv pip install --system .

# Copy the rest of the application code
COPY . .

# Second stage: runtime image
FROM python:3.11-slim

WORKDIR /app

# Create a non-root user
RUN useradd --create-home appuser

# Copy the virtual environment from the builder stage
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# Copy application code
COPY server.py .

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONPATH=/app

# Switch to the non-root user
USER appuser

# Command to run the MCP server
CMD ["uv", "run", "server.py"]
