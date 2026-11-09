-- Run as the database owner (for example, postgres).
\set ON_ERROR_STOP on
BEGIN;

\echo '1. Confirm sample students'
SELECT id, name, email FROM public.students ORDER BY id;

\echo '2. Demonstrate UPDATE and DELETE audit events'
UPDATE public.students SET name = 'Kofi M.' WHERE email = 'kofi@example.test';
DELETE FROM public.students WHERE email = 'abena@example.test';

\echo '3. Inspect audit records'
SELECT tbl, op, old_row ->> 'name' AS was, new_row ->> 'name' AS now,
       changed_by, at
FROM public.audit_log
WHERE tbl = 'students'
ORDER BY at DESC, id DESC
LIMIT 10;

\echo '4. Walk the category hierarchy'
WITH RECURSIVE tree AS (
    SELECT id, name, parent_id, 0 AS depth
    FROM public.categories
    WHERE parent_id IS NULL
    UNION ALL
    SELECT c.id, c.name, c.parent_id, t.depth + 1
    FROM public.categories AS c
    JOIN tree AS t ON c.parent_id = t.id
)
SELECT repeat('  ', depth) || name AS category_tree, id, parent_id, depth
FROM tree
ORDER BY depth, name;

\echo '5. Inspect application roles'
SELECT rolname, rolcanlogin
FROM pg_roles
WHERE rolname IN ('app_read', 'app_write')
ORDER BY rolname;

-- Undo demonstration changes and their audit rows.
ROLLBACK;
