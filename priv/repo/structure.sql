--
-- PostgreSQL database dump
--

-- Dumped from database version 10.3
-- Dumped by pg_dump version 10.3

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
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


--
-- Name: invitation_state; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.invitation_state AS ENUM (
    'PENDING',
    'ACCEPTED',
    'REVOKED'
);


--
-- Name: room_state; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.room_state AS ENUM (
    'ACTIVE',
    'DELETED'
);


--
-- Name: room_subscriber_policy; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.room_subscriber_policy AS ENUM (
    'MANDATORY',
    'PUBLIC',
    'INVITE_ONLY'
);


--
-- Name: space_state; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.space_state AS ENUM (
    'ACTIVE',
    'DISABLED'
);


--
-- Name: user_role; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.user_role AS ENUM (
    'OWNER',
    'ADMIN',
    'MEMBER'
);


--
-- Name: user_state; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.user_state AS ENUM (
    'ACTIVE',
    'DISABLED'
);


--
-- Name: next_global_id(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.next_global_id(OUT result bigint) RETURNS bigint
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

CREATE TABLE public.drafts (
    id bigint DEFAULT public.next_global_id() NOT NULL,
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

CREATE SEQUENCE public.global_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: invitations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.invitations (
    id bigint DEFAULT public.next_global_id() NOT NULL,
    space_id bigint NOT NULL,
    invitor_id bigint NOT NULL,
    acceptor_id bigint,
    state public.invitation_state DEFAULT 'PENDING'::public.invitation_state NOT NULL,
    role public.user_role DEFAULT 'MEMBER'::public.user_role NOT NULL,
    email text NOT NULL,
    token uuid NOT NULL,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: room_messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.room_messages (
    id bigint DEFAULT public.next_global_id() NOT NULL,
    space_id bigint NOT NULL,
    user_id bigint NOT NULL,
    room_id bigint NOT NULL,
    body text NOT NULL,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: room_subscriptions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.room_subscriptions (
    id bigint DEFAULT public.next_global_id() NOT NULL,
    space_id bigint NOT NULL,
    user_id bigint NOT NULL,
    room_id bigint NOT NULL,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    last_read_message_id bigint,
    last_read_message_at timestamp without time zone
);


--
-- Name: rooms; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rooms (
    id bigint DEFAULT public.next_global_id() NOT NULL,
    space_id bigint NOT NULL,
    creator_id bigint NOT NULL,
    state public.room_state DEFAULT 'ACTIVE'::public.room_state NOT NULL,
    name text NOT NULL,
    description text DEFAULT ''::text NOT NULL,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    subscriber_policy public.room_subscriber_policy DEFAULT 'PUBLIC'::public.room_subscriber_policy
);


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version bigint NOT NULL,
    inserted_at timestamp without time zone
);


--
-- Name: spaces; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.spaces (
    id bigint DEFAULT public.next_global_id() NOT NULL,
    state public.space_state DEFAULT 'ACTIVE'::public.space_state NOT NULL,
    name text NOT NULL,
    slug text NOT NULL,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id bigint DEFAULT public.next_global_id() NOT NULL,
    space_id bigint NOT NULL,
    state public.user_state DEFAULT 'ACTIVE'::public.user_state NOT NULL,
    role public.user_role DEFAULT 'MEMBER'::public.user_role NOT NULL,
    email text NOT NULL,
    first_name text,
    last_name text,
    time_zone text NOT NULL,
    password_hash text NOT NULL,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    session_salt text DEFAULT 'salt'::text NOT NULL
);


--
-- Name: drafts drafts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.drafts
    ADD CONSTRAINT drafts_pkey PRIMARY KEY (id);


--
-- Name: invitations invitations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invitations
    ADD CONSTRAINT invitations_pkey PRIMARY KEY (id);


--
-- Name: room_messages room_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.room_messages
    ADD CONSTRAINT room_messages_pkey PRIMARY KEY (id);


--
-- Name: room_subscriptions room_subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.room_subscriptions
    ADD CONSTRAINT room_subscriptions_pkey PRIMARY KEY (id);


--
-- Name: rooms rooms_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rooms
    ADD CONSTRAINT rooms_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: spaces spaces_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.spaces
    ADD CONSTRAINT spaces_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: drafts_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX drafts_id_index ON public.drafts USING btree (id);


--
-- Name: drafts_user_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX drafts_user_id_index ON public.drafts USING btree (user_id);


--
-- Name: invitations_invitor_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX invitations_invitor_id_index ON public.invitations USING btree (invitor_id);


--
-- Name: invitations_space_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX invitations_space_id_index ON public.invitations USING btree (space_id);


--
-- Name: invitations_token_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX invitations_token_index ON public.invitations USING btree (token);


--
-- Name: invitations_unique_pending_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX invitations_unique_pending_email ON public.invitations USING btree (lower(email)) WHERE (state = 'PENDING'::public.invitation_state);


--
-- Name: room_messages_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX room_messages_id_index ON public.room_messages USING btree (id);


--
-- Name: room_messages_room_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX room_messages_room_id_index ON public.room_messages USING btree (room_id);


--
-- Name: room_subscriptions_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX room_subscriptions_id_index ON public.room_subscriptions USING btree (id);


--
-- Name: room_subscriptions_room_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX room_subscriptions_room_id_index ON public.room_subscriptions USING btree (room_id);


--
-- Name: room_subscriptions_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX room_subscriptions_unique ON public.room_subscriptions USING btree (user_id, room_id);


--
-- Name: room_subscriptions_user_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX room_subscriptions_user_id_index ON public.room_subscriptions USING btree (user_id);


--
-- Name: rooms_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX rooms_id_index ON public.rooms USING btree (id);


--
-- Name: rooms_space_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX rooms_space_id_index ON public.rooms USING btree (space_id);


--
-- Name: rooms_unique_ci_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX rooms_unique_ci_name ON public.rooms USING btree (space_id, lower(name)) WHERE (NOT (state = 'DELETED'::public.room_state));


--
-- Name: spaces_slug_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX spaces_slug_index ON public.spaces USING btree (slug);


--
-- Name: users_space_id_email_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX users_space_id_email_index ON public.users USING btree (space_id, email);


--
-- Name: users_space_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX users_space_id_index ON public.users USING btree (space_id);


--
-- Name: drafts drafts_space_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.drafts
    ADD CONSTRAINT drafts_space_id_fkey FOREIGN KEY (space_id) REFERENCES public.spaces(id);


--
-- Name: drafts drafts_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.drafts
    ADD CONSTRAINT drafts_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: invitations invitations_acceptor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invitations
    ADD CONSTRAINT invitations_acceptor_id_fkey FOREIGN KEY (acceptor_id) REFERENCES public.users(id);


--
-- Name: invitations invitations_invitor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invitations
    ADD CONSTRAINT invitations_invitor_id_fkey FOREIGN KEY (invitor_id) REFERENCES public.users(id);


--
-- Name: invitations invitations_space_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invitations
    ADD CONSTRAINT invitations_space_id_fkey FOREIGN KEY (space_id) REFERENCES public.spaces(id);


--
-- Name: room_messages room_messages_room_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.room_messages
    ADD CONSTRAINT room_messages_room_id_fkey FOREIGN KEY (room_id) REFERENCES public.rooms(id);


--
-- Name: room_messages room_messages_space_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.room_messages
    ADD CONSTRAINT room_messages_space_id_fkey FOREIGN KEY (space_id) REFERENCES public.spaces(id);


--
-- Name: room_messages room_messages_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.room_messages
    ADD CONSTRAINT room_messages_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: room_subscriptions room_subscriptions_last_read_message_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.room_subscriptions
    ADD CONSTRAINT room_subscriptions_last_read_message_id_fkey FOREIGN KEY (last_read_message_id) REFERENCES public.room_messages(id);


--
-- Name: room_subscriptions room_subscriptions_room_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.room_subscriptions
    ADD CONSTRAINT room_subscriptions_room_id_fkey FOREIGN KEY (room_id) REFERENCES public.rooms(id);


--
-- Name: room_subscriptions room_subscriptions_space_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.room_subscriptions
    ADD CONSTRAINT room_subscriptions_space_id_fkey FOREIGN KEY (space_id) REFERENCES public.spaces(id);


--
-- Name: room_subscriptions room_subscriptions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.room_subscriptions
    ADD CONSTRAINT room_subscriptions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: rooms rooms_creator_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rooms
    ADD CONSTRAINT rooms_creator_id_fkey FOREIGN KEY (creator_id) REFERENCES public.users(id);


--
-- Name: rooms rooms_space_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rooms
    ADD CONSTRAINT rooms_space_id_fkey FOREIGN KEY (space_id) REFERENCES public.spaces(id);


--
-- Name: users users_space_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_space_id_fkey FOREIGN KEY (space_id) REFERENCES public.spaces(id);


--
-- PostgreSQL database dump complete
--

INSERT INTO "schema_migrations" (version) VALUES (20170526045329), (20170527220454), (20170528000152), (20170715050656), (20170822002819), (20171005144526), (20171005223147), (20171006221016), (20171006224345), (20171028185025), (20180206160730), (20180206173101), (20180402172104);

