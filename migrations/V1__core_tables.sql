-- V1: Core application table used by the audit trigger lab.
CREATE TABLE public.students (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT students_name_not_blank CHECK (length(btrim(name)) > 0)
);

INSERT INTO public.students (name, email)
VALUES ('Ama Mensah', 'ama@example.test'),
       ('Kofi Boateng', 'kofi@example.test'),
       ('Abena Owusu', 'abena@example.test');
