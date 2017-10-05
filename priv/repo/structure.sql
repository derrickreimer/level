--
-- PostgreSQL database dump
--

-- Dumped from database version 9.6.3
-- Dumped by pg_dump version 9.6.3

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

--
-- Name: invitation_state; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE invitation_state AS ENUM (
    'PENDING',
    'ACCEPTED',
    'REVOKED'
);


--
-- Name: room_state; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE room_state AS ENUM (
    'ACTIVE',
    'DELETED'
);


--
-- Name: space_state; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE space_state AS ENUM (
    'ACTIVE',
    'DISABLED'
);


--
-- Name: user_role; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE user_role AS ENUM (
    'OWNER',
    'ADMIN',
    'MEMBER'
);


--
-- Name: user_state; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE user_state AS ENUM (
    'ACTIVE',
    'DISABLED'
);


--
-- Name: next_global_id(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION next_global_id(OUT result bigint) RETURNS bigint
    LANGUAGE plpgsql
    AS $$
DECLARE
    our_epoch bigint := 1501268767000;
    seq_id bigint;
    now_millis bigint;
    shard_id int := 1;
BEGIN
    SELECT nextval('global_id_seq') % 1024 INTO seq_id;

    SELECT FLOOR(EXTRACT(EPOCH FROM clock_timestamp()) * 1000) INTO now_millis;
    result := (now_millis - our_epoch) << 23;
    result := result | (shard_id << 10);
    result := result | (seq_id);
END;
$$;


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: drafts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE drafts (
    id bigint DEFAULT next_global_id() NOT NULL,
    space_id bigint NOT NULL,
    user_id bigint NOT NULL,
    recipient_ids text[] DEFAULT ARRAY[]::text[] NOT NULL,
    subject text DEFAULT ''::text NOT NULL,
    body text DEFAULT ''::text NOT NULL,
    is_truncated boolean DEFAULT false NOT NULL,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: global_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE global_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: invitations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE invitations (
    id bigint DEFAULT next_global_id() NOT NULL,
    space_id bigint NOT NULL,
    invitor_id bigint NOT NULL,
    acceptor_id bigint,
    state invitation_state DEFAULT 'PENDING'::invitation_state NOT NULL,
    role user_role DEFAULT 'MEMBER'::user_role NOT NULL,
    email text NOT NULL,
    token uuid NOT NULL,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: rooms; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE rooms (
    id bigint DEFAULT next_global_id() NOT NULL,
    space_id bigint NOT NULL,
    creator_id bigint NOT NULL,
    state room_state DEFAULT 'ACTIVE'::room_state NOT NULL,
    name text NOT NULL,
    description text DEFAULT ''::text NOT NULL,
    is_private boolean DEFAULT false NOT NULL,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE schema_migrations (
    version bigint NOT NULL,
    inserted_at timestamp without time zone
);


--
-- Name: spaces; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE spaces (
    id bigint DEFAULT next_global_id() NOT NULL,
    state space_state DEFAULT 'ACTIVE'::space_state NOT NULL,
    name text NOT NULL,
    slug text NOT NULL,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE users (
    id bigint DEFAULT next_global_id() NOT NULL,
    space_id bigint NOT NULL,
    state user_state DEFAULT 'ACTIVE'::user_state NOT NULL,
    role user_role DEFAULT 'MEMBER'::user_role NOT NULL,
    email text NOT NULL,
    username text NOT NULL,
    first_name text,
    last_name text,
    time_zone text NOT NULL,
    password_hash text NOT NULL,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: drafts drafts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY drafts
    ADD CONSTRAINT drafts_pkey PRIMARY KEY (id);


--
-- Name: invitations invitations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY invitations
    ADD CONSTRAINT invitations_pkey PRIMARY KEY (id);


--
-- Name: rooms rooms_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY rooms
    ADD CONSTRAINT rooms_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: spaces spaces_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY spaces
    ADD CONSTRAINT spaces_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: drafts_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX drafts_id_index ON drafts USING btree (id);


--
-- Name: drafts_user_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX drafts_user_id_index ON drafts USING btree (user_id);


--
-- Name: invitations_invitor_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX invitations_invitor_id_index ON invitations USING btree (invitor_id);


--
-- Name: invitations_space_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX invitations_space_id_index ON invitations USING btree (space_id);


--
-- Name: invitations_token_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX invitations_token_index ON invitations USING btree (token);


--
-- Name: invitations_unique_pending_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX invitations_unique_pending_email ON invitations USING btree (lower(email)) WHERE (state = 'PENDING'::invitation_state);


--
-- Name: rooms_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX rooms_id_index ON rooms USING btree (id);


--
-- Name: rooms_space_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX rooms_space_id_index ON rooms USING btree (space_id);


--
-- Name: rooms_unique_ci_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX rooms_unique_ci_name ON rooms USING btree (space_id, lower(name)) WHERE (NOT (state = 'DELETED'::room_state));


--
-- Name: spaces_slug_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX spaces_slug_index ON spaces USING btree (slug);


--
-- Name: users_space_id_email_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX users_space_id_email_index ON users USING btree (space_id, email);


--
-- Name: users_space_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX users_space_id_index ON users USING btree (space_id);


--
-- Name: users_space_id_username_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX users_space_id_username_index ON users USING btree (space_id, username);


--
-- Name: drafts drafts_space_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY drafts
    ADD CONSTRAINT drafts_space_id_fkey FOREIGN KEY (space_id) REFERENCES spaces(id);


--
-- Name: drafts drafts_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY drafts
    ADD CONSTRAINT drafts_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: invitations invitations_acceptor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY invitations
    ADD CONSTRAINT invitations_acceptor_id_fkey FOREIGN KEY (acceptor_id) REFERENCES users(id);


--
-- Name: invitations invitations_invitor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY invitations
    ADD CONSTRAINT invitations_invitor_id_fkey FOREIGN KEY (invitor_id) REFERENCES users(id);


--
-- Name: invitations invitations_space_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY invitations
    ADD CONSTRAINT invitations_space_id_fkey FOREIGN KEY (space_id) REFERENCES spaces(id);


--
-- Name: rooms rooms_creator_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY rooms
    ADD CONSTRAINT rooms_creator_id_fkey FOREIGN KEY (creator_id) REFERENCES users(id);


--
-- Name: rooms rooms_space_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY rooms
    ADD CONSTRAINT rooms_space_id_fkey FOREIGN KEY (space_id) REFERENCES spaces(id);


--
-- Name: users users_space_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_space_id_fkey FOREIGN KEY (space_id) REFERENCES spaces(id);


--
-- PostgreSQL database dump complete
--

INSERT INTO "schema_migrations" (version) VALUES (20170526045329), (20170527220454), (20170528000152), (20170715050656), (20170822002819), (20171005144526);

