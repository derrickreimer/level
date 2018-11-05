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
-- Name: citext; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA public;


--
-- Name: EXTENSION citext; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION citext IS 'data type for case-insensitive character strings';


--
-- Name: bot_state; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.bot_state AS ENUM (
    'ACTIVE',
    'DISABLED'
);


--
-- Name: group_state; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.group_state AS ENUM (
    'OPEN',
    'CLOSED',
    'DELETED'
);


--
-- Name: group_user_role; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.group_user_role AS ENUM (
    'MEMBER',
    'OWNER'
);


--
-- Name: group_user_state; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.group_user_state AS ENUM (
    'NOT_SUBSCRIBED',
    'SUBSCRIBED'
);


--
-- Name: inbox_state; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.inbox_state AS ENUM (
    'UNREAD',
    'READ',
    'DISMISSED',
    'EXCLUDED'
);


--
-- Name: open_invitation_state; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.open_invitation_state AS ENUM (
    'ACTIVE',
    'REVOKED'
);


--
-- Name: post_log_event; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.post_log_event AS ENUM (
    'POST_CREATED',
    'POST_EDITED',
    'POST_CLOSED',
    'POST_REOPENED',
    'REPLY_CREATED',
    'REPLY_EDITED',
    'REPLY_DELETED'
);


--
-- Name: post_state; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.post_state AS ENUM (
    'OPEN',
    'CLOSED'
);


--
-- Name: post_subscription_state; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.post_subscription_state AS ENUM (
    'NOT_SUBSCRIBED',
    'SUBSCRIBED',
    'UNSUBSCRIBED'
);


--
-- Name: post_user_log_event; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.post_user_log_event AS ENUM (
    'MARKED_AS_READ',
    'MARKED_AS_UNREAD',
    'DISMISSED',
    'SUBSCRIBED',
    'UNSUBSCRIBED'
);


--
-- Name: space_bot_state; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.space_bot_state AS ENUM (
    'ACTIVE',
    'DISABLED'
);


--
-- Name: space_setup_state; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.space_setup_state AS ENUM (
    'CREATE_GROUPS',
    'INVITE_USERS',
    'COMPLETE'
);


--
-- Name: space_state; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.space_state AS ENUM (
    'ACTIVE',
    'DISABLED'
);


--
-- Name: space_user_role; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.space_user_role AS ENUM (
    'OWNER',
    'ADMIN',
    'MEMBER'
);


--
-- Name: space_user_state; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.space_user_state AS ENUM (
    'ACTIVE',
    'DISABLED'
);


--
-- Name: user_state; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.user_state AS ENUM (
    'ACTIVE',
    'DISABLED'
);


--
-- Name: posts_search_vector_trigger(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.posts_search_vector_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
  new.search_vector :=
     to_tsvector(new.language::regconfig, new.body);
  return new;
end
$$;


--
-- Name: replies_search_vector_trigger(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.replies_search_vector_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
  new.search_vector :=
     to_tsvector(new.language::regconfig, new.body);
  return new;
end
$$;


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: bots; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bots (
    id uuid NOT NULL,
    state public.bot_state DEFAULT 'ACTIVE'::public.bot_state NOT NULL,
    handle public.citext NOT NULL,
    display_name text NOT NULL,
    avatar text,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: digest_sections; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.digest_sections (
    id uuid NOT NULL,
    space_id uuid NOT NULL,
    digest_id uuid NOT NULL,
    title text NOT NULL,
    summary text,
    summary_html text,
    link_text text,
    link_url text,
    rank integer,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: digests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.digests (
    id uuid NOT NULL,
    space_id uuid NOT NULL,
    space_user_id uuid NOT NULL,
    title text NOT NULL,
    start_at timestamp without time zone NOT NULL,
    end_at timestamp without time zone NOT NULL,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: files; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.files (
    id uuid NOT NULL,
    space_id uuid NOT NULL,
    space_user_id uuid NOT NULL,
    filename text NOT NULL,
    content_type text,
    size integer NOT NULL,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: group_bookmarks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.group_bookmarks (
    id uuid NOT NULL,
    space_id uuid NOT NULL,
    space_user_id uuid NOT NULL,
    group_id uuid NOT NULL,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: group_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.group_users (
    id uuid NOT NULL,
    space_id uuid NOT NULL,
    space_user_id uuid NOT NULL,
    group_id uuid NOT NULL,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    state public.group_user_state DEFAULT 'NOT_SUBSCRIBED'::public.group_user_state NOT NULL,
    role public.group_user_role DEFAULT 'MEMBER'::public.group_user_role NOT NULL
);


--
-- Name: groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.groups (
    id uuid NOT NULL,
    space_id uuid NOT NULL,
    creator_id uuid NOT NULL,
    state public.group_state DEFAULT 'OPEN'::public.group_state NOT NULL,
    name text NOT NULL,
    description text,
    is_private boolean DEFAULT false NOT NULL,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    is_default boolean DEFAULT false NOT NULL
);


--
-- Name: open_invitations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.open_invitations (
    id uuid NOT NULL,
    space_id uuid NOT NULL,
    state public.open_invitation_state DEFAULT 'ACTIVE'::public.open_invitation_state NOT NULL,
    token text NOT NULL,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: password_resets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.password_resets (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    expires_at timestamp without time zone NOT NULL,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: post_files; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.post_files (
    id uuid NOT NULL,
    space_id uuid NOT NULL,
    post_id uuid NOT NULL,
    file_id uuid NOT NULL,
    inserted_at timestamp without time zone NOT NULL
);


--
-- Name: post_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.post_groups (
    id uuid NOT NULL,
    space_id uuid NOT NULL,
    post_id uuid NOT NULL,
    group_id uuid NOT NULL,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: post_locators; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.post_locators (
    id uuid NOT NULL,
    space_id uuid NOT NULL,
    post_id uuid NOT NULL,
    scope text NOT NULL,
    topic text NOT NULL,
    key text NOT NULL,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: post_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.post_log (
    id uuid NOT NULL,
    event public.post_log_event NOT NULL,
    occurred_at timestamp without time zone NOT NULL,
    space_id uuid NOT NULL,
    post_id uuid NOT NULL,
    group_id uuid,
    actor_id uuid,
    reply_id uuid
);


--
-- Name: posts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.posts (
    id uuid NOT NULL,
    space_id uuid NOT NULL,
    space_user_id uuid,
    state public.post_state DEFAULT 'OPEN'::public.post_state NOT NULL,
    body text NOT NULL,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    language text DEFAULT 'english'::text NOT NULL,
    search_vector tsvector,
    space_bot_id uuid
);


--
-- Name: replies; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.replies (
    id uuid NOT NULL,
    space_id uuid NOT NULL,
    space_user_id uuid,
    post_id uuid NOT NULL,
    body text NOT NULL,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    language text DEFAULT 'english'::text NOT NULL,
    search_vector tsvector,
    space_bot_id uuid
);


--
-- Name: post_searches; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.post_searches AS
 SELECT posts.space_id,
    posts.id AS searchable_id,
    'Post'::text AS searchable_type,
    posts.id AS post_id,
    posts.body AS document,
    posts.search_vector,
    (posts.language)::regconfig AS language
   FROM public.posts
UNION
 SELECT replies.space_id,
    replies.id AS searchable_id,
    'Reply'::text AS searchable_type,
    replies.post_id,
    replies.body AS document,
    replies.search_vector,
    (replies.language)::regconfig AS language
   FROM public.replies;


--
-- Name: post_user_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.post_user_log (
    id uuid NOT NULL,
    event public.post_user_log_event NOT NULL,
    occurred_at timestamp without time zone NOT NULL,
    space_id uuid NOT NULL,
    post_id uuid NOT NULL,
    space_user_id uuid
);


--
-- Name: post_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.post_users (
    id uuid NOT NULL,
    space_id uuid NOT NULL,
    post_id uuid NOT NULL,
    space_user_id uuid NOT NULL,
    subscription_state public.post_subscription_state DEFAULT 'NOT_SUBSCRIBED'::public.post_subscription_state NOT NULL,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    inbox_state public.inbox_state DEFAULT 'EXCLUDED'::public.inbox_state NOT NULL
);


--
-- Name: post_versions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.post_versions (
    id uuid NOT NULL,
    space_id uuid NOT NULL,
    post_id uuid NOT NULL,
    author_id uuid NOT NULL,
    body text NOT NULL,
    inserted_at timestamp without time zone NOT NULL
);


--
-- Name: post_views; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.post_views (
    id uuid NOT NULL,
    space_id uuid NOT NULL,
    post_id uuid NOT NULL,
    space_user_id uuid NOT NULL,
    last_viewed_reply_id uuid,
    occurred_at timestamp without time zone NOT NULL
);


--
-- Name: push_subscriptions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.push_subscriptions (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    digest text NOT NULL,
    data text NOT NULL,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: reply_files; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reply_files (
    id uuid NOT NULL,
    space_id uuid NOT NULL,
    reply_id uuid NOT NULL,
    file_id uuid NOT NULL,
    inserted_at timestamp without time zone NOT NULL
);


--
-- Name: reply_versions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reply_versions (
    id uuid NOT NULL,
    space_id uuid NOT NULL,
    reply_id uuid NOT NULL,
    author_id uuid NOT NULL,
    body text NOT NULL,
    inserted_at timestamp without time zone NOT NULL
);


--
-- Name: reply_views; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reply_views (
    id uuid NOT NULL,
    space_id uuid NOT NULL,
    post_id uuid NOT NULL,
    reply_id uuid NOT NULL,
    space_user_id uuid NOT NULL,
    occurred_at timestamp without time zone NOT NULL
);


--
-- Name: reservations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reservations (
    id uuid NOT NULL,
    email public.citext NOT NULL,
    handle public.citext NOT NULL,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version bigint NOT NULL,
    inserted_at timestamp without time zone
);


--
-- Name: space_bots; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.space_bots (
    id uuid NOT NULL,
    space_id uuid NOT NULL,
    bot_id uuid NOT NULL,
    state public.space_bot_state DEFAULT 'ACTIVE'::public.space_bot_state NOT NULL,
    handle public.citext NOT NULL,
    display_name text NOT NULL,
    avatar text,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: space_setup_steps; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.space_setup_steps (
    id uuid NOT NULL,
    space_id uuid NOT NULL,
    space_user_id uuid NOT NULL,
    state public.space_setup_state NOT NULL,
    is_skipped boolean NOT NULL,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: space_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.space_users (
    id uuid NOT NULL,
    space_id uuid NOT NULL,
    user_id uuid NOT NULL,
    state public.space_user_state DEFAULT 'ACTIVE'::public.space_user_state NOT NULL,
    role public.space_user_role DEFAULT 'MEMBER'::public.space_user_role NOT NULL,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    first_name text NOT NULL,
    last_name text NOT NULL,
    avatar text,
    handle public.citext NOT NULL
);


--
-- Name: spaces; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.spaces (
    id uuid NOT NULL,
    state public.space_state DEFAULT 'ACTIVE'::public.space_state NOT NULL,
    name text NOT NULL,
    slug public.citext NOT NULL,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    avatar text
);


--
-- Name: user_mentions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_mentions (
    id uuid NOT NULL,
    space_id uuid NOT NULL,
    post_id uuid NOT NULL,
    reply_id uuid,
    mentioner_id uuid NOT NULL,
    mentioned_id uuid NOT NULL,
    dismissed_at timestamp without time zone,
    occurred_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id uuid NOT NULL,
    state public.user_state DEFAULT 'ACTIVE'::public.user_state NOT NULL,
    email public.citext NOT NULL,
    first_name text NOT NULL,
    last_name text NOT NULL,
    time_zone text NOT NULL,
    password_hash text,
    session_salt text DEFAULT 'salt'::text NOT NULL,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    avatar text,
    handle public.citext NOT NULL
);


--
-- Name: bots bots_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bots
    ADD CONSTRAINT bots_pkey PRIMARY KEY (id);


--
-- Name: digest_sections digest_sections_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.digest_sections
    ADD CONSTRAINT digest_sections_pkey PRIMARY KEY (id);


--
-- Name: digests digests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.digests
    ADD CONSTRAINT digests_pkey PRIMARY KEY (id);


--
-- Name: files files_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.files
    ADD CONSTRAINT files_pkey PRIMARY KEY (id);


--
-- Name: group_bookmarks group_bookmarks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_bookmarks
    ADD CONSTRAINT group_bookmarks_pkey PRIMARY KEY (id);


--
-- Name: group_users group_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_users
    ADD CONSTRAINT group_users_pkey PRIMARY KEY (id);


--
-- Name: groups groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.groups
    ADD CONSTRAINT groups_pkey PRIMARY KEY (id);


--
-- Name: open_invitations open_invitations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.open_invitations
    ADD CONSTRAINT open_invitations_pkey PRIMARY KEY (id);


--
-- Name: password_resets password_resets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.password_resets
    ADD CONSTRAINT password_resets_pkey PRIMARY KEY (id);


--
-- Name: post_files post_files_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_files
    ADD CONSTRAINT post_files_pkey PRIMARY KEY (id);


--
-- Name: post_groups post_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_groups
    ADD CONSTRAINT post_groups_pkey PRIMARY KEY (id);


--
-- Name: post_locators post_locators_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_locators
    ADD CONSTRAINT post_locators_pkey PRIMARY KEY (id);


--
-- Name: post_log post_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_log
    ADD CONSTRAINT post_log_pkey PRIMARY KEY (id);


--
-- Name: post_user_log post_user_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_user_log
    ADD CONSTRAINT post_user_log_pkey PRIMARY KEY (id);


--
-- Name: post_users post_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_users
    ADD CONSTRAINT post_users_pkey PRIMARY KEY (id);


--
-- Name: post_versions post_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_versions
    ADD CONSTRAINT post_versions_pkey PRIMARY KEY (id);


--
-- Name: post_views post_views_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_views
    ADD CONSTRAINT post_views_pkey PRIMARY KEY (id);


--
-- Name: posts posts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posts
    ADD CONSTRAINT posts_pkey PRIMARY KEY (id);


--
-- Name: push_subscriptions push_subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.push_subscriptions
    ADD CONSTRAINT push_subscriptions_pkey PRIMARY KEY (id);


--
-- Name: replies replies_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.replies
    ADD CONSTRAINT replies_pkey PRIMARY KEY (id);


--
-- Name: reply_files reply_files_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reply_files
    ADD CONSTRAINT reply_files_pkey PRIMARY KEY (id);


--
-- Name: reply_versions reply_versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reply_versions
    ADD CONSTRAINT reply_versions_pkey PRIMARY KEY (id);


--
-- Name: reply_views reply_views_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reply_views
    ADD CONSTRAINT reply_views_pkey PRIMARY KEY (id);


--
-- Name: reservations reservations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reservations
    ADD CONSTRAINT reservations_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: space_bots space_bots_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.space_bots
    ADD CONSTRAINT space_bots_pkey PRIMARY KEY (id);


--
-- Name: space_setup_steps space_setup_steps_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.space_setup_steps
    ADD CONSTRAINT space_setup_steps_pkey PRIMARY KEY (id);


--
-- Name: space_users space_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.space_users
    ADD CONSTRAINT space_users_pkey PRIMARY KEY (id);


--
-- Name: spaces spaces_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.spaces
    ADD CONSTRAINT spaces_pkey PRIMARY KEY (id);


--
-- Name: user_mentions user_mentions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_mentions
    ADD CONSTRAINT user_mentions_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: bots_lower_handle_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX bots_lower_handle_index ON public.bots USING btree (lower((handle)::text));


--
-- Name: group_bookmarks_space_user_id_group_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX group_bookmarks_space_user_id_group_id_index ON public.group_bookmarks USING btree (space_user_id, group_id);


--
-- Name: group_users_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX group_users_id_index ON public.group_users USING btree (id);


--
-- Name: group_users_space_user_id_group_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX group_users_space_user_id_group_id_index ON public.group_users USING btree (space_user_id, group_id);


--
-- Name: groups_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX groups_id_index ON public.groups USING btree (id);


--
-- Name: groups_space_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX groups_space_id_index ON public.groups USING btree (space_id);


--
-- Name: groups_unique_names_when_undeleted; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX groups_unique_names_when_undeleted ON public.groups USING btree (space_id, lower(name)) WHERE (NOT (state = 'DELETED'::public.group_state));


--
-- Name: open_invitations_token_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX open_invitations_token_index ON public.open_invitations USING btree (token);


--
-- Name: open_invitations_unique_active; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX open_invitations_unique_active ON public.open_invitations USING btree (space_id) WHERE (state = 'ACTIVE'::public.open_invitation_state);


--
-- Name: post_files_post_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX post_files_post_id_index ON public.post_files USING btree (post_id);


--
-- Name: post_groups_post_id_group_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX post_groups_post_id_group_id_index ON public.post_groups USING btree (post_id, group_id);


--
-- Name: post_locators_space_id_scope_topic_key_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX post_locators_space_id_scope_topic_key_index ON public.post_locators USING btree (space_id, scope, topic, key);


--
-- Name: post_users_post_id_space_user_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX post_users_post_id_space_user_id_index ON public.post_users USING btree (post_id, space_user_id);


--
-- Name: post_versions_post_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX post_versions_post_id_index ON public.post_versions USING btree (post_id);


--
-- Name: posts_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX posts_id_index ON public.posts USING btree (id);


--
-- Name: posts_search_vector_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX posts_search_vector_index ON public.posts USING gin (search_vector);


--
-- Name: push_subscriptions_user_id_digest_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX push_subscriptions_user_id_digest_index ON public.push_subscriptions USING btree (user_id, digest);


--
-- Name: replies_search_vector_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX replies_search_vector_index ON public.replies USING gin (search_vector);


--
-- Name: reply_files_reply_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX reply_files_reply_id_index ON public.reply_files USING btree (reply_id);


--
-- Name: reply_versions_reply_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX reply_versions_reply_id_index ON public.reply_versions USING btree (reply_id);


--
-- Name: reservations_lower_email_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX reservations_lower_email_index ON public.reservations USING btree (lower((email)::text));


--
-- Name: reservations_lower_handle_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX reservations_lower_handle_index ON public.reservations USING btree (lower((handle)::text));


--
-- Name: space_bots_space_id_lower_handle_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX space_bots_space_id_lower_handle_index ON public.space_bots USING btree (space_id, lower((handle)::text));


--
-- Name: space_setup_steps_space_id_state_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX space_setup_steps_space_id_state_index ON public.space_setup_steps USING btree (space_id, state);


--
-- Name: space_users_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX space_users_id_index ON public.space_users USING btree (id);


--
-- Name: space_users_space_id_lower_handle_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX space_users_space_id_lower_handle_index ON public.space_users USING btree (space_id, lower((handle)::text));


--
-- Name: space_users_space_id_user_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX space_users_space_id_user_id_index ON public.space_users USING btree (space_id, user_id);


--
-- Name: spaces_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX spaces_id_index ON public.spaces USING btree (id);


--
-- Name: spaces_lower_slug_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX spaces_lower_slug_index ON public.spaces USING btree (lower((slug)::text));


--
-- Name: users_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX users_id_index ON public.users USING btree (id);


--
-- Name: users_lower_email_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX users_lower_email_index ON public.users USING btree (lower((email)::text));


--
-- Name: users_lower_handle_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX users_lower_handle_index ON public.users USING btree (lower((handle)::text));


--
-- Name: posts update_search_vector; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_search_vector BEFORE INSERT OR UPDATE ON public.posts FOR EACH ROW EXECUTE PROCEDURE public.posts_search_vector_trigger();


--
-- Name: replies update_search_vector; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_search_vector BEFORE INSERT OR UPDATE ON public.replies FOR EACH ROW EXECUTE PROCEDURE public.replies_search_vector_trigger();


--
-- Name: digest_sections digest_sections_digest_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.digest_sections
    ADD CONSTRAINT digest_sections_digest_id_fkey FOREIGN KEY (digest_id) REFERENCES public.digests(id);


--
-- Name: digest_sections digest_sections_space_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.digest_sections
    ADD CONSTRAINT digest_sections_space_id_fkey FOREIGN KEY (space_id) REFERENCES public.spaces(id);


--
-- Name: digests digests_space_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.digests
    ADD CONSTRAINT digests_space_id_fkey FOREIGN KEY (space_id) REFERENCES public.spaces(id);


--
-- Name: digests digests_space_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.digests
    ADD CONSTRAINT digests_space_user_id_fkey FOREIGN KEY (space_user_id) REFERENCES public.space_users(id);


--
-- Name: files files_space_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.files
    ADD CONSTRAINT files_space_id_fkey FOREIGN KEY (space_id) REFERENCES public.spaces(id);


--
-- Name: files files_space_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.files
    ADD CONSTRAINT files_space_user_id_fkey FOREIGN KEY (space_user_id) REFERENCES public.space_users(id);


--
-- Name: group_bookmarks group_bookmarks_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_bookmarks
    ADD CONSTRAINT group_bookmarks_group_id_fkey FOREIGN KEY (group_id) REFERENCES public.groups(id);


--
-- Name: group_bookmarks group_bookmarks_space_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_bookmarks
    ADD CONSTRAINT group_bookmarks_space_id_fkey FOREIGN KEY (space_id) REFERENCES public.spaces(id);


--
-- Name: group_bookmarks group_bookmarks_space_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_bookmarks
    ADD CONSTRAINT group_bookmarks_space_user_id_fkey FOREIGN KEY (space_user_id) REFERENCES public.space_users(id);


--
-- Name: group_users group_users_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_users
    ADD CONSTRAINT group_users_group_id_fkey FOREIGN KEY (group_id) REFERENCES public.groups(id);


--
-- Name: group_users group_users_space_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_users
    ADD CONSTRAINT group_users_space_id_fkey FOREIGN KEY (space_id) REFERENCES public.spaces(id);


--
-- Name: group_users group_users_space_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_users
    ADD CONSTRAINT group_users_space_user_id_fkey FOREIGN KEY (space_user_id) REFERENCES public.space_users(id);


--
-- Name: groups groups_creator_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.groups
    ADD CONSTRAINT groups_creator_id_fkey FOREIGN KEY (creator_id) REFERENCES public.space_users(id);


--
-- Name: groups groups_space_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.groups
    ADD CONSTRAINT groups_space_id_fkey FOREIGN KEY (space_id) REFERENCES public.spaces(id);


--
-- Name: open_invitations open_invitations_space_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.open_invitations
    ADD CONSTRAINT open_invitations_space_id_fkey FOREIGN KEY (space_id) REFERENCES public.spaces(id);


--
-- Name: password_resets password_resets_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.password_resets
    ADD CONSTRAINT password_resets_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: post_files post_files_file_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_files
    ADD CONSTRAINT post_files_file_id_fkey FOREIGN KEY (file_id) REFERENCES public.files(id) ON DELETE CASCADE;


--
-- Name: post_files post_files_post_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_files
    ADD CONSTRAINT post_files_post_id_fkey FOREIGN KEY (post_id) REFERENCES public.posts(id);


--
-- Name: post_files post_files_space_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_files
    ADD CONSTRAINT post_files_space_id_fkey FOREIGN KEY (space_id) REFERENCES public.spaces(id);


--
-- Name: post_groups post_groups_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_groups
    ADD CONSTRAINT post_groups_group_id_fkey FOREIGN KEY (group_id) REFERENCES public.groups(id);


--
-- Name: post_groups post_groups_post_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_groups
    ADD CONSTRAINT post_groups_post_id_fkey FOREIGN KEY (post_id) REFERENCES public.posts(id);


--
-- Name: post_groups post_groups_space_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_groups
    ADD CONSTRAINT post_groups_space_id_fkey FOREIGN KEY (space_id) REFERENCES public.spaces(id);


--
-- Name: post_locators post_locators_post_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_locators
    ADD CONSTRAINT post_locators_post_id_fkey FOREIGN KEY (post_id) REFERENCES public.posts(id);


--
-- Name: post_locators post_locators_space_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_locators
    ADD CONSTRAINT post_locators_space_id_fkey FOREIGN KEY (space_id) REFERENCES public.spaces(id);


--
-- Name: post_log post_log_actor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_log
    ADD CONSTRAINT post_log_actor_id_fkey FOREIGN KEY (actor_id) REFERENCES public.space_users(id);


--
-- Name: post_log post_log_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_log
    ADD CONSTRAINT post_log_group_id_fkey FOREIGN KEY (group_id) REFERENCES public.groups(id);


--
-- Name: post_log post_log_post_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_log
    ADD CONSTRAINT post_log_post_id_fkey FOREIGN KEY (post_id) REFERENCES public.posts(id);


--
-- Name: post_log post_log_reply_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_log
    ADD CONSTRAINT post_log_reply_id_fkey FOREIGN KEY (reply_id) REFERENCES public.replies(id);


--
-- Name: post_log post_log_space_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_log
    ADD CONSTRAINT post_log_space_id_fkey FOREIGN KEY (space_id) REFERENCES public.spaces(id);


--
-- Name: post_user_log post_user_log_post_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_user_log
    ADD CONSTRAINT post_user_log_post_id_fkey FOREIGN KEY (post_id) REFERENCES public.posts(id);


--
-- Name: post_user_log post_user_log_space_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_user_log
    ADD CONSTRAINT post_user_log_space_id_fkey FOREIGN KEY (space_id) REFERENCES public.spaces(id);


--
-- Name: post_user_log post_user_log_space_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_user_log
    ADD CONSTRAINT post_user_log_space_user_id_fkey FOREIGN KEY (space_user_id) REFERENCES public.space_users(id);


--
-- Name: post_users post_users_post_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_users
    ADD CONSTRAINT post_users_post_id_fkey FOREIGN KEY (post_id) REFERENCES public.posts(id);


--
-- Name: post_users post_users_space_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_users
    ADD CONSTRAINT post_users_space_id_fkey FOREIGN KEY (space_id) REFERENCES public.spaces(id);


--
-- Name: post_users post_users_space_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_users
    ADD CONSTRAINT post_users_space_user_id_fkey FOREIGN KEY (space_user_id) REFERENCES public.space_users(id);


--
-- Name: post_versions post_versions_author_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_versions
    ADD CONSTRAINT post_versions_author_id_fkey FOREIGN KEY (author_id) REFERENCES public.space_users(id);


--
-- Name: post_versions post_versions_post_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_versions
    ADD CONSTRAINT post_versions_post_id_fkey FOREIGN KEY (post_id) REFERENCES public.posts(id);


--
-- Name: post_versions post_versions_space_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_versions
    ADD CONSTRAINT post_versions_space_id_fkey FOREIGN KEY (space_id) REFERENCES public.spaces(id);


--
-- Name: post_views post_views_last_viewed_reply_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_views
    ADD CONSTRAINT post_views_last_viewed_reply_id_fkey FOREIGN KEY (last_viewed_reply_id) REFERENCES public.replies(id);


--
-- Name: post_views post_views_post_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_views
    ADD CONSTRAINT post_views_post_id_fkey FOREIGN KEY (post_id) REFERENCES public.posts(id);


--
-- Name: post_views post_views_space_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_views
    ADD CONSTRAINT post_views_space_id_fkey FOREIGN KEY (space_id) REFERENCES public.spaces(id);


--
-- Name: post_views post_views_space_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.post_views
    ADD CONSTRAINT post_views_space_user_id_fkey FOREIGN KEY (space_user_id) REFERENCES public.space_users(id);


--
-- Name: posts posts_space_bot_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posts
    ADD CONSTRAINT posts_space_bot_id_fkey FOREIGN KEY (space_bot_id) REFERENCES public.space_bots(id);


--
-- Name: posts posts_space_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posts
    ADD CONSTRAINT posts_space_id_fkey FOREIGN KEY (space_id) REFERENCES public.spaces(id);


--
-- Name: posts posts_space_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posts
    ADD CONSTRAINT posts_space_user_id_fkey FOREIGN KEY (space_user_id) REFERENCES public.space_users(id);


--
-- Name: push_subscriptions push_subscriptions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.push_subscriptions
    ADD CONSTRAINT push_subscriptions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: replies replies_post_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.replies
    ADD CONSTRAINT replies_post_id_fkey FOREIGN KEY (post_id) REFERENCES public.posts(id);


--
-- Name: replies replies_space_bot_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.replies
    ADD CONSTRAINT replies_space_bot_id_fkey FOREIGN KEY (space_bot_id) REFERENCES public.space_bots(id);


--
-- Name: replies replies_space_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.replies
    ADD CONSTRAINT replies_space_id_fkey FOREIGN KEY (space_id) REFERENCES public.spaces(id);


--
-- Name: replies replies_space_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.replies
    ADD CONSTRAINT replies_space_user_id_fkey FOREIGN KEY (space_user_id) REFERENCES public.space_users(id);


--
-- Name: reply_files reply_files_file_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reply_files
    ADD CONSTRAINT reply_files_file_id_fkey FOREIGN KEY (file_id) REFERENCES public.files(id) ON DELETE CASCADE;


--
-- Name: reply_files reply_files_reply_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reply_files
    ADD CONSTRAINT reply_files_reply_id_fkey FOREIGN KEY (reply_id) REFERENCES public.replies(id);


--
-- Name: reply_files reply_files_space_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reply_files
    ADD CONSTRAINT reply_files_space_id_fkey FOREIGN KEY (space_id) REFERENCES public.spaces(id);


--
-- Name: reply_versions reply_versions_author_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reply_versions
    ADD CONSTRAINT reply_versions_author_id_fkey FOREIGN KEY (author_id) REFERENCES public.space_users(id);


--
-- Name: reply_versions reply_versions_reply_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reply_versions
    ADD CONSTRAINT reply_versions_reply_id_fkey FOREIGN KEY (reply_id) REFERENCES public.replies(id);


--
-- Name: reply_versions reply_versions_space_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reply_versions
    ADD CONSTRAINT reply_versions_space_id_fkey FOREIGN KEY (space_id) REFERENCES public.spaces(id);


--
-- Name: reply_views reply_views_post_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reply_views
    ADD CONSTRAINT reply_views_post_id_fkey FOREIGN KEY (post_id) REFERENCES public.posts(id);


--
-- Name: reply_views reply_views_reply_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reply_views
    ADD CONSTRAINT reply_views_reply_id_fkey FOREIGN KEY (reply_id) REFERENCES public.replies(id);


--
-- Name: reply_views reply_views_space_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reply_views
    ADD CONSTRAINT reply_views_space_id_fkey FOREIGN KEY (space_id) REFERENCES public.spaces(id);


--
-- Name: reply_views reply_views_space_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reply_views
    ADD CONSTRAINT reply_views_space_user_id_fkey FOREIGN KEY (space_user_id) REFERENCES public.space_users(id);


--
-- Name: space_bots space_bots_bot_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.space_bots
    ADD CONSTRAINT space_bots_bot_id_fkey FOREIGN KEY (bot_id) REFERENCES public.bots(id);


--
-- Name: space_bots space_bots_space_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.space_bots
    ADD CONSTRAINT space_bots_space_id_fkey FOREIGN KEY (space_id) REFERENCES public.spaces(id);


--
-- Name: space_setup_steps space_setup_steps_space_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.space_setup_steps
    ADD CONSTRAINT space_setup_steps_space_id_fkey FOREIGN KEY (space_id) REFERENCES public.spaces(id);


--
-- Name: space_setup_steps space_setup_steps_space_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.space_setup_steps
    ADD CONSTRAINT space_setup_steps_space_user_id_fkey FOREIGN KEY (space_user_id) REFERENCES public.space_users(id);


--
-- Name: space_users space_users_space_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.space_users
    ADD CONSTRAINT space_users_space_id_fkey FOREIGN KEY (space_id) REFERENCES public.spaces(id);


--
-- Name: space_users space_users_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.space_users
    ADD CONSTRAINT space_users_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: user_mentions user_mentions_mentioned_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_mentions
    ADD CONSTRAINT user_mentions_mentioned_id_fkey FOREIGN KEY (mentioned_id) REFERENCES public.space_users(id);


--
-- Name: user_mentions user_mentions_mentioner_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_mentions
    ADD CONSTRAINT user_mentions_mentioner_id_fkey FOREIGN KEY (mentioner_id) REFERENCES public.space_users(id);


--
-- Name: user_mentions user_mentions_post_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_mentions
    ADD CONSTRAINT user_mentions_post_id_fkey FOREIGN KEY (post_id) REFERENCES public.posts(id);


--
-- Name: user_mentions user_mentions_reply_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_mentions
    ADD CONSTRAINT user_mentions_reply_id_fkey FOREIGN KEY (reply_id) REFERENCES public.replies(id);


--
-- Name: user_mentions user_mentions_space_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_mentions
    ADD CONSTRAINT user_mentions_space_id_fkey FOREIGN KEY (space_id) REFERENCES public.spaces(id);


--
-- PostgreSQL database dump complete
--

INSERT INTO public."schema_migrations" (version) VALUES (20170527220454), (20170528000152), (20170619214118), (20180403181445), (20180404204544), (20180413214033), (20180509143149), (20180510211015), (20180515174533), (20180518203612), (20180531200436), (20180627000743), (20180627231041), (20180724162650), (20180725135511), (20180731205027), (20180803151120), (20180807173948), (20180809201313), (20180810141122), (20180903213417), (20180903215930), (20180903220826), (20180908173406), (20180918182427), (20181003182443), (20181005154158), (20181009210537), (20181010174443), (20181011172259), (20181012200233), (20181012223338), (20181014144651), (20181018210912), (20181019194025), (20181022151255), (20181023175556), (20181029191737), (20181029220713), (20181101221239), (20181103215151), (20181105181343), (20181105195328);

