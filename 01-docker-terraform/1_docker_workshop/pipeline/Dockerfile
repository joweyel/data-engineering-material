FROM python:3.13.11-slim

# Copy from existing Docker image the folder /uv to /bin
COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin

# Setting workdirectory 
WORKDIR /code

# Puts uv's python binary in path (no `uv run` needed in entrypoint)
ENV PATH="/code/.venv/bin:$PATH"

COPY pyproject.toml .python-version uv.lock ./

# Install dependencies specified in uv.lock files
RUN uv sync --locked


# Copy file into container
COPY pipeline.py .

# Executes this command upon entering container
ENTRYPOINT [ "python3", "pipeline.py" ]