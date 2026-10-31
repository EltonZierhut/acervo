SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


--
-- Name: immutable_array_to_string(text[], text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.immutable_array_to_string(text[], text) RETURNS text
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $_$ SELECT array_to_string($1, $2) $_$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: codes_snippets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.codes_snippets (
    id bigint NOT NULL,
    title character varying,
    description text,
    language character varying,
    content text NOT NULL,
    tags character varying[] DEFAULT '{}'::character varying[] NOT NULL,
    searchable tsvector GENERATED ALWAYS AS (((((setweight(to_tsvector('simple'::regconfig, (COALESCE(title, ''::character varying))::text), 'A'::"char") || setweight(to_tsvector('simple'::regconfig, public.immutable_array_to_string((tags)::text[], ' '::text)), 'A'::"char")) || setweight(to_tsvector('simple'::regconfig, (COALESCE(language, ''::character varying))::text), 'B'::"char")) || setweight(to_tsvector('simple'::regconfig, COALESCE(description, ''::text)), 'B'::"char")) || setweight(to_tsvector('simple'::regconfig, COALESCE(content, ''::text)), 'C'::"char"))) STORED,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    tags_text text GENERATED ALWAYS AS (public.immutable_array_to_string((tags)::text[], ' '::text)) STORED
);


--
-- Name: codes_snippets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.codes_snippets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: codes_snippets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.codes_snippets_id_seq OWNED BY public.codes_snippets.id;


--
-- Name: initiatives_contexts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.initiatives_contexts (
    id bigint NOT NULL,
    name character varying NOT NULL,
    color character varying DEFAULT '#6b7380'::character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: initiatives_contexts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.initiatives_contexts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: initiatives_contexts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.initiatives_contexts_id_seq OWNED BY public.initiatives_contexts.id;


--
-- Name: initiatives_initiatives; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.initiatives_initiatives (
    id bigint NOT NULL,
    context_id bigint,
    name character varying NOT NULL,
    description text,
    status character varying DEFAULT 'planned'::character varying NOT NULL,
    priority character varying DEFAULT 'medium'::character varying NOT NULL,
    starts_on date,
    due_on date,
    tags character varying[] DEFAULT '{}'::character varying[] NOT NULL,
    sections character varying[] DEFAULT '{tasks,milestones}'::character varying[] NOT NULL,
    tags_text text GENERATED ALWAYS AS (public.immutable_array_to_string((tags)::text[], ' '::text)) STORED,
    searchable tsvector GENERATED ALWAYS AS (((setweight(to_tsvector('simple'::regconfig, (COALESCE(name, ''::character varying))::text), 'A'::"char") || setweight(to_tsvector('simple'::regconfig, public.immutable_array_to_string((tags)::text[], ' '::text)), 'A'::"char")) || setweight(to_tsvector('simple'::regconfig, COALESCE(description, ''::text)), 'B'::"char"))) STORED,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT initiatives_dates_check CHECK (((due_on IS NULL) OR (starts_on IS NULL) OR (due_on >= starts_on))),
    CONSTRAINT initiatives_priority_check CHECK (((priority)::text = ANY ((ARRAY['low'::character varying, 'medium'::character varying, 'high'::character varying])::text[]))),
    CONSTRAINT initiatives_status_check CHECK (((status)::text = ANY ((ARRAY['idea'::character varying, 'planned'::character varying, 'active'::character varying, 'paused'::character varying, 'done'::character varying])::text[])))
);


--
-- Name: initiatives_initiatives_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.initiatives_initiatives_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: initiatives_initiatives_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.initiatives_initiatives_id_seq OWNED BY public.initiatives_initiatives.id;


--
-- Name: initiatives_milestones; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.initiatives_milestones (
    id bigint NOT NULL,
    initiative_id bigint NOT NULL,
    title character varying NOT NULL,
    description text,
    due_on date,
    completed_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: initiatives_milestones_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.initiatives_milestones_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: initiatives_milestones_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.initiatives_milestones_id_seq OWNED BY public.initiatives_milestones.id;


--
-- Name: initiatives_tasks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.initiatives_tasks (
    id bigint NOT NULL,
    initiative_id bigint NOT NULL,
    milestone_id bigint,
    title character varying NOT NULL,
    description text,
    status character varying DEFAULT 'todo'::character varying NOT NULL,
    priority character varying DEFAULT 'medium'::character varying NOT NULL,
    due_on date,
    completed_at timestamp(6) without time zone,
    searchable tsvector GENERATED ALWAYS AS ((setweight(to_tsvector('simple'::regconfig, (COALESCE(title, ''::character varying))::text), 'A'::"char") || setweight(to_tsvector('simple'::regconfig, COALESCE(description, ''::text)), 'B'::"char"))) STORED,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT initiatives_tasks_priority_check CHECK (((priority)::text = ANY ((ARRAY['low'::character varying, 'medium'::character varying, 'high'::character varying])::text[]))),
    CONSTRAINT initiatives_tasks_status_check CHECK (((status)::text = ANY ((ARRAY['todo'::character varying, 'doing'::character varying, 'done'::character varying])::text[])))
);


--
-- Name: initiatives_tasks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.initiatives_tasks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: initiatives_tasks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.initiatives_tasks_id_seq OWNED BY public.initiatives_tasks.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sessions (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    token character varying NOT NULL,
    ip_address character varying,
    user_agent character varying,
    last_active_at timestamp(6) without time zone NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: sessions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sessions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sessions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sessions_id_seq OWNED BY public.sessions.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    email_address character varying NOT NULL,
    password_digest character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: codes_snippets id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.codes_snippets ALTER COLUMN id SET DEFAULT nextval('public.codes_snippets_id_seq'::regclass);


--
-- Name: initiatives_contexts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.initiatives_contexts ALTER COLUMN id SET DEFAULT nextval('public.initiatives_contexts_id_seq'::regclass);


--
-- Name: initiatives_initiatives id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.initiatives_initiatives ALTER COLUMN id SET DEFAULT nextval('public.initiatives_initiatives_id_seq'::regclass);


--
-- Name: initiatives_milestones id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.initiatives_milestones ALTER COLUMN id SET DEFAULT nextval('public.initiatives_milestones_id_seq'::regclass);


--
-- Name: initiatives_tasks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.initiatives_tasks ALTER COLUMN id SET DEFAULT nextval('public.initiatives_tasks_id_seq'::regclass);


--
-- Name: sessions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessions ALTER COLUMN id SET DEFAULT nextval('public.sessions_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: codes_snippets codes_snippets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.codes_snippets
    ADD CONSTRAINT codes_snippets_pkey PRIMARY KEY (id);


--
-- Name: initiatives_contexts initiatives_contexts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.initiatives_contexts
    ADD CONSTRAINT initiatives_contexts_pkey PRIMARY KEY (id);


--
-- Name: initiatives_initiatives initiatives_initiatives_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.initiatives_initiatives
    ADD CONSTRAINT initiatives_initiatives_pkey PRIMARY KEY (id);


--
-- Name: initiatives_milestones initiatives_milestones_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.initiatives_milestones
    ADD CONSTRAINT initiatives_milestones_pkey PRIMARY KEY (id);


--
-- Name: initiatives_tasks initiatives_tasks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.initiatives_tasks
    ADD CONSTRAINT initiatives_tasks_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: sessions sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: index_codes_snippets_on_content; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_codes_snippets_on_content ON public.codes_snippets USING gin (content public.gin_trgm_ops);


--
-- Name: index_codes_snippets_on_searchable; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_codes_snippets_on_searchable ON public.codes_snippets USING gin (searchable);


--
-- Name: index_codes_snippets_on_tags; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_codes_snippets_on_tags ON public.codes_snippets USING gin (tags);


--
-- Name: index_codes_snippets_on_title; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_codes_snippets_on_title ON public.codes_snippets USING gin (title public.gin_trgm_ops);


--
-- Name: index_initiatives_contexts_on_lower_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_initiatives_contexts_on_lower_name ON public.initiatives_contexts USING btree (lower((name)::text));


--
-- Name: index_initiatives_initiatives_on_context_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_initiatives_initiatives_on_context_id ON public.initiatives_initiatives USING btree (context_id);


--
-- Name: index_initiatives_initiatives_on_name_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_initiatives_initiatives_on_name_trgm ON public.initiatives_initiatives USING gin (name public.gin_trgm_ops);


--
-- Name: index_initiatives_initiatives_on_searchable; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_initiatives_initiatives_on_searchable ON public.initiatives_initiatives USING gin (searchable);


--
-- Name: index_initiatives_initiatives_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_initiatives_initiatives_on_status ON public.initiatives_initiatives USING btree (status);


--
-- Name: index_initiatives_initiatives_on_tags; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_initiatives_initiatives_on_tags ON public.initiatives_initiatives USING gin (tags);


--
-- Name: index_initiatives_milestones_on_initiative_id_and_due_on; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_initiatives_milestones_on_initiative_id_and_due_on ON public.initiatives_milestones USING btree (initiative_id, due_on);


--
-- Name: index_initiatives_tasks_on_initiative_id_and_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_initiatives_tasks_on_initiative_id_and_status ON public.initiatives_tasks USING btree (initiative_id, status);


--
-- Name: index_initiatives_tasks_on_milestone_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_initiatives_tasks_on_milestone_id ON public.initiatives_tasks USING btree (milestone_id);


--
-- Name: index_initiatives_tasks_on_searchable; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_initiatives_tasks_on_searchable ON public.initiatives_tasks USING gin (searchable);


--
-- Name: index_initiatives_tasks_on_title_trgm; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_initiatives_tasks_on_title_trgm ON public.initiatives_tasks USING gin (title public.gin_trgm_ops);


--
-- Name: index_sessions_on_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_sessions_on_token ON public.sessions USING btree (token);


--
-- Name: index_sessions_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_sessions_on_user_id ON public.sessions USING btree (user_id);


--
-- Name: index_users_on_email_address; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_email_address ON public.users USING btree (email_address);


--
-- Name: initiatives_tasks fk_rails_0957f09212; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.initiatives_tasks
    ADD CONSTRAINT fk_rails_0957f09212 FOREIGN KEY (milestone_id) REFERENCES public.initiatives_milestones(id) ON DELETE SET NULL;


--
-- Name: initiatives_milestones fk_rails_2efaed1aab; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.initiatives_milestones
    ADD CONSTRAINT fk_rails_2efaed1aab FOREIGN KEY (initiative_id) REFERENCES public.initiatives_initiatives(id) ON DELETE CASCADE;


--
-- Name: sessions fk_rails_758836b4f0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT fk_rails_758836b4f0 FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: initiatives_initiatives fk_rails_b76c736c28; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.initiatives_initiatives
    ADD CONSTRAINT fk_rails_b76c736c28 FOREIGN KEY (context_id) REFERENCES public.initiatives_contexts(id) ON DELETE SET NULL;


--
-- Name: initiatives_tasks fk_rails_e855c4fa67; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.initiatives_tasks
    ADD CONSTRAINT fk_rails_e855c4fa67 FOREIGN KEY (initiative_id) REFERENCES public.initiatives_initiatives(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20261031000001'),
('20261030000004'),
('20261030000003'),
('20261030000002'),
('20261030000001');

