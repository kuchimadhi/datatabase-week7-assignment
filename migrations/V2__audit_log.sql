-- V2: Store row images for INSERT, UPDATE, and DELETE operations.
CREATE TABLE public.audit_log (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tbl TEXT NOT NULL,
    op TEXT NOT NULL CHECK (op IN ('INSERT', 'UPDATE', 'DELETE')),
    old_row JSONB,
    new_row JSONB,
    changed_by TEXT NOT NULL DEFAULT current_user,
    at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT audit_log_row_image_check CHECK (
        (op = 'INSERT' AND old_row IS NULL AND new_row IS NOT NULL)
        OR (op = 'UPDATE' AND old_row IS NOT NULL AND new_row IS NOT NULL)
        OR (op = 'DELETE' AND old_row IS NOT NULL AND new_row IS NULL)
    )
);

CREATE INDEX idx_audit_log_table_time ON public.audit_log (tbl, at DESC);

CREATE OR REPLACE FUNCTION public.audit()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO public.audit_log (tbl, op, old_row, new_row)
        VALUES (TG_TABLE_NAME, TG_OP, NULL, to_jsonb(NEW));
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO public.audit_log (tbl, op, old_row, new_row)
        VALUES (TG_TABLE_NAME, TG_OP, to_jsonb(OLD), to_jsonb(NEW));
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO public.audit_log (tbl, op, old_row, new_row)
        VALUES (TG_TABLE_NAME, TG_OP, to_jsonb(OLD), NULL);
        RETURN OLD;
    END IF;
    RAISE EXCEPTION 'Unsupported audit operation: %', TG_OP;
END;
$$;

REVOKE ALL ON FUNCTION public.audit() FROM PUBLIC;

CREATE TRIGGER trg_audit_students
AFTER INSERT OR UPDATE OR DELETE ON public.students
FOR EACH ROW EXECUTE FUNCTION public.audit();
