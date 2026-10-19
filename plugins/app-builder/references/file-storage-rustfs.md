# File uploads with RustFS

Add RustFS only when the app needs to store files people upload (photos,
documents, attachments). RustFS is an S3-compatible storage server that runs as
one more container in this app's compose project.

## 1. Look up the current details first

At build time, check the official RustFS docs (https://docs.rustfs.com and the
`rustfs/rustfs` image page) for:
- the image name and the latest stable version tag. **Pin that exact version**
  (never `latest`),
- the environment variables for the access key and secret key,
- the S3 API port inside the container (9000 at the time of writing) and the
  data directory.

The snippet below matches the docs at the time of writing. Correct it to what
the docs say now, and log the version in DECISIONS.md.

## 2. Compose service

Add to `compose.yml`, with **no `ports:`** (it's only reachable inside Docker):

```yaml
  rustfs:
    image: rustfs/rustfs:<pinned-version>
    environment:
      RUSTFS_ACCESS_KEY: ${STORAGE_ACCESS_KEY:?STORAGE_ACCESS_KEY is not set in .env}
      RUSTFS_SECRET_KEY: ${STORAGE_SECRET_KEY:?STORAGE_SECRET_KEY is not set in .env}
    volumes:
      - storage-data:/data
```

and `storage-data:` under the top-level `volumes:`. Add `rustfs` to the
backend's `depends_on`.

In `.env.example` (empty values), and in `.env` (new-app style: generate them
with `openssl rand -hex 20` and write them in, then tell her they're there):

```
# File storage (RustFS, only reachable inside Docker)
STORAGE_ACCESS_KEY=
STORAGE_SECRET_KEY=
STORAGE_BUCKET=uploads
```

Matching settings in `backend/app/core/config.py`, plus
`STORAGE_ENDPOINT: str = "http://rustfs:9000"`.

## 3. Backend storage service

Add `boto3` (`docker compose exec backend uv add --no-sync boto3`, then
`docker compose up -d --build`). Create `backend/app/services/storage_service.py`:

- A client: `boto3.client("s3", endpoint_url=settings.STORAGE_ENDPOINT,
  aws_access_key_id=..., aws_secret_access_key=..., region_name="us-east-1")`.
- `ensure_bucket()`: create the bucket if missing (call it from `seed.py`, it's idempotent).
- `upload(file, key) -> key`
- `download(key) -> stream` and `delete(key)`.
- Store only the object key (and original filename, size, content type) in the
  database model, never the file itself.

## 4. Validate every upload

In the route (FastAPI `UploadFile`), before calling the service:
- **Size**: reject anything over a limit agreed with her (e.g. 10 MB) with a
  clear message. Read in chunks and stop once over the limit.
- **Type**: allow a short list of content types and extensions for this
  feature (e.g. `image/jpeg`, `image/png`, `application/pdf`). Reject others.
- Generate the object key yourself (e.g. `f"{entity_id}/{uuid4()}{ext}"`);
  never use the uploaded filename as the key.

## 5. Downloads

Serve files **through the backend**, e.g. `GET /api/v1/<things>/{id}/file`,
which checks the user may see it, then streams it from RustFS
(`StreamingResponse`, with `Content-Type` and `Content-Disposition`). This
goes through the app's single port (`APP_PORT`, via the Vite proxy). Never
publish a RustFS port and never hand out RustFS URLs to the browser.

## 6. Wrap up

- Add `"rustfs"` to `services` in `.app-builder.json` and the services line in `CLAUDE.md`.
- Seed: call `ensure_bucket()` in `run_all()`.
- `./scripts/reset-db.sh` only wipes the database. Files stay in the
  `storage-data` volume; mention it to her if it matters.
