# Installing dependencies into a virtualenv

FROM python:3.12-slim AS builder

WORKDIR /build

# Installing something thats is needed to create a clean venv and install wheels
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && pip install --no-cache-dir -r requirements.txt

# ----------------------------------------------------------------
# Runtime stage - minimal image, non-root user

FROM python:3.12-slim AS runtime

# Creating a non-root user and group
RUN groupadd --gid 10001 app && useradd --uid 10001 --gid app --shell /bin/false --create-home app

WORKDIR /app

# Copying the virtual environment from the builder 
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Copy application code
COPY --chown=app:app app.py .

# Drop privileges
USER app

# Exposing the port the app listens on
EXPOSE 8080

# Healthcheck against the /healthz endpoint
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8080/healthz')" || exit 1

# Running the application
CMD ["python", "app.py"]