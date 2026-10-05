FROM python:3.12-slim AS builder

WORKDIR /build
COPY requirements.txt .
RUN python -m pip install --no-cache-dir --prefix=/install -r requirements.txt

FROM python:3.12-slim AS runtime

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app
COPY --from=builder /install /usr/local
COPY app.py .

RUN addgroup --system --gid 10001 app \
    && adduser --system --uid 10001 --ingroup app app

USER 10001:10001
EXPOSE 5000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD python -c "from urllib.request import urlopen; urlopen('http://127.0.0.1:5000/health', timeout=2)" || exit 1

CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "--threads", "4", "--access-logfile", "-", "--error-logfile", "-", "app:app"]