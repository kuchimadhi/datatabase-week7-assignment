-- V3: Adjacency-list category hierarchy.
CREATE TABLE public.categories (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name TEXT NOT NULL,
    parent_id BIGINT REFERENCES public.categories(id) ON DELETE RESTRICT,
    CONSTRAINT categories_name_not_blank CHECK (length(btrim(name)) > 0),
    CONSTRAINT categories_not_own_parent CHECK (parent_id IS NULL OR parent_id <> id)
);

CREATE INDEX idx_categories_parent_id ON public.categories (parent_id);

INSERT INTO public.categories (name, parent_id) VALUES ('Electronics', NULL);

INSERT INTO public.categories (name, parent_id)
SELECT 'Computers', id FROM public.categories
WHERE name = 'Electronics' AND parent_id IS NULL;

INSERT INTO public.categories (name, parent_id)
SELECT 'Phones', id FROM public.categories
WHERE name = 'Electronics' AND parent_id IS NULL;

INSERT INTO public.categories (name, parent_id)
SELECT 'Laptops', id FROM public.categories WHERE name = 'Computers';
