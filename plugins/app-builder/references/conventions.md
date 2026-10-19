# Coding conventions

Charbel reviews this code. Keep it boring, consistent and close to the template.

## Folder structure, and the order to build a feature

The "items" feature is the canonical example. Copy its shape for every feature:

1. **Model**: `backend/app/models/<thing>.py`. One file per domain entity:
   the SQLModel table plus `<Thing>Create`, `<Thing>Update`, `<Thing>Public`,
   `<Thing>sPublic` schemas. Import it in `backend/app/models/__init__.py`.
2. **Migration / seed**: see `database-changes.md`. Update `backend/app/seed.py`.
3. **Service**: `backend/app/services/<thing>_service.py`. All business rules
   and all database queries. Functions take keyword arguments
   (`session=`, `user=`, ...).
4. **Route**: `backend/app/api/routes/<things>.py`. HTTP only: parse input,
   call a service, return a schema. Include the router in `backend/app/api/main.py`.
5. **Regenerate the client**: `./scripts/generate-client.sh`.
6. **Queries**: TanStack Query hooks (`useQuery` / `useSuspenseQuery`,
   `useMutation`) calling the generated `<Thing>sService`. Invalidate the list's
   query key after a mutation.
7. **Page and components**: `frontend/src/routes/_layout/<things>.tsx` (file-based
   route, logged-in layout) and `frontend/src/components/<Things>/`. Add it to
   the sidebar in `frontend/src/components/Sidebar/AppSidebar.tsx`.

## Naming

- Python: `snake_case` functions and modules, `PascalCase` classes. Table names
  come from the class name (`Item` → `item`).
- Routes: plural nouns (`/api/v1/items/`), standard verbs (GET list, GET one,
  POST, PUT, DELETE).
- TypeScript: `PascalCase` components in `PascalCase.tsx` files, `camelCase`
  functions and variables.
- Use the business's own words for things (a "visit", not a "record").

## Error handling

- Services raise domain errors from `app/services/errors.py`: `NotFoundError`,
  `PermissionDeniedError`, `ConflictError`, or `DomainError` (400) for other
  broken business rules. Never raise `HTTPException` in a service.
- `app/main.py` turns domain errors into HTTP responses with `{"detail": message}`.
- Routes raise `HTTPException` only for HTTP-level problems.
- Error messages are plain English; the frontend shows them to users in a toast
  (`handleError` in `frontend/src/utils.ts`).

## Pagination

- List endpoints take `skip` and `limit` (default 100) and return
  `{"data": [...], "count": total}` (see `ItemsPublic`).
- The service returns `(rows, count)`; the route builds the `...Public` schema.
- The frontend table (`components/Common/DataTable.tsx`) pages through what it
  loaded. For lists that can grow past a few hundred rows, pass `skip`/`limit`
  from the page instead.

## UI

- Use shadcn/ui components (`frontend/src/components/ui/`) before writing custom UI.
  Add a missing one inside the frontend container:
  `docker compose exec frontend bunx shadcn@latest add <component>`.
- Forms: React Hook Form + Zod (`zodResolver`), like `components/Items/AddItem.tsx`.
- Show success and errors with `useCustomToast`.

## Never

- Never hand-edit `frontend/src/client/` (generated) or `frontend/src/routeTree.gen.ts`.
- Never leave dead code, commented-out code or unused files.

## Quality bar

- `./scripts/check.sh` must pass: ruff (lint + format) and pytest on the backend,
  Biome and the TypeScript build on the frontend. Fix formatting with
  `docker compose exec backend ruff format app` and
  `docker compose exec frontend bun run lint`.
- Tests stay minimal: smoke tests for critical flows only (login, the main
  flow of each important feature). Put them in `backend/app/tests/`.

## Removing the example feature

Once the app has its own first real feature, remove "items" completely: model,
service, routes, router include, seed function, tests, frontend route,
components, sidebar entry, and regenerate the client. Write a migration (or
reset, per `database-changes.md`) that drops the table.
