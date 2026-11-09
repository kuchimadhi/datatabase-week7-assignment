# Hands-On Lab: Audit Logging, Category Trees, and Safe Migrations

A PostgreSQL implementation of the Week 7 lab: JSONB row-level auditing, recursive category queries, Flyway migrations, least-privilege roles, and verification.

## Requirements
- PostgreSQL 14+
- Flyway Community Edition CLI
- psql or another PostgreSQL client

## Layout
- migrations/V1__core_tables.sql — students table and sample rows
- migrations/V2__audit_log.sql — audit_log, trigger function, and trigger
- migrations/V3__categories.sql — category hierarchy and sample tree
- migrations/V4__least_privilege_roles.sql — app_read and app_write roles
- sql/verify_lab.sql — rollback-safe verification script
- flyway.conf.example — local Flyway configuration template

## 1. Create the database
Run as a PostgreSQL administrator:
```sql
CREATE DATABASE bootcamp;
```
Then connect:
```sh
psql -h localhost -U postgres -d bootcamp
```

## 2. Configure and run Flyway
Copy flyway.conf.example to flyway.conf and set the connection settings locally. Keep real passwords out of Git.
```sh
export FLYWAY_URL="jdbc:postgresql://localhost:5432/bootcamp"
export FLYWAY_USER="postgres"
export FLYWAY_PASSWORD="your-local-admin-password"
flyway -configFiles=flyway.conf migrate
flyway -configFiles=flyway.conf info
```
Flyway applies migrations in version order and records versions/checksums in flyway_schema_history. Never edit an already-applied migration; add a new version for future changes.

## 3. Verify the lab
```sh
psql -h localhost -U postgres -d bootcamp -f sql/verify_lab.sql
```
The script demonstrates UPDATE and DELETE auditing, displays the category hierarchy, checks role creation, and rolls back its demonstration changes.

## 4. Implementation notes

### Audit logging
The trigger captures INSERT, UPDATE, and DELETE row images as JSONB. For INSERT, old_row is NULL; for DELETE, new_row is NULL. The trigger function is SECURITY DEFINER with a fixed search_path, allowing application writers to change student rows without direct INSERT permission on audit_log. Audit records share the source transaction, so rolled-back changes do not leave audit rows.

### Category tree
categories.parent_id is a self-referencing foreign key. The recursive CTE starts at roots (parent_id IS NULL) and finds descendants while tracking depth.

### Least privilege
Migration V4 creates two NOLOGIN group roles:
- app_read: SELECT access to tables and sequences.
- app_write: SELECT, INSERT, UPDATE, DELETE access to tables and required sequence usage.

Create an individual login as an administrator and set its password interactively:
```sql
CREATE ROLE api LOGIN IN ROLE app_write;
\password api
```
For read-only access, create a login in app_read instead. Do not store shared or hard-coded passwords in migration files or source control.

## 5. Useful inspection queries
```sql
SELECT installed_rank, version, description, success
FROM flyway_schema_history
ORDER BY installed_rank;

SELECT tbl, op, changed_by, at, old_row, new_row
FROM public.audit_log
ORDER BY at DESC
LIMIT 20;

WITH RECURSIVE tree AS (
    SELECT id, name, parent_id, 0 AS depth
    FROM public.categories
    WHERE parent_id IS NULL
    UNION ALL
    SELECT c.id, c.name, c.parent_id, t.depth + 1
    FROM public.categories AS c
    JOIN tree AS t ON c.parent_id = t.id
)
SELECT repeat('  ', depth) || name AS category, id, parent_id, depth
FROM tree
ORDER BY depth, name;
```

## Notes
- These migrations assume a fresh bootcamp database and public schema.
- The audit trigger is attached to public.students.
- Sample names and email addresses are reserved example data.
