FROM python:3.12-slim AS build

WORKDIR /w

COPY requirements.txt .

RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

FROM python:3.12-slim

# Apply the available Debian security update for zlib
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       zlib1g=1:1.3.dfsg+really1.3.1-1+deb13u1 \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -r -u 10001 app

WORKDIR /app

COPY --from=build /install /usr/local
COPY --chown=app:app app.py .

USER app

EXPOSE 5000

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:5000/health', timeout=2)"

CMD ["python", "app.py"]