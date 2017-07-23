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


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: invitations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE invitations (
    id integer NOT NULL,
    team_id integer NOT NULL,
    invitor_id integer NOT NULL,
    acceptor_id integer,
    state invitation_state DEFAULT 'PENDING'::invitation_state NOT NULL,
    role user_role DEFAULT 'MEMBER'::user_role NOT NULL,
    email character varying(255) NOT NULL,
    token character varying(36) NOT NULL,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: invitations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE invitations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: invitations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE invitations_id_seq OWNED BY invitations.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE schema_migrations (
    version bigint NOT NULL,
    inserted_at timestamp without time zone
);


--
-- Name: teams; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE teams (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    state integer NOT NULL,
    slug character varying(63) NOT NULL,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: teams_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE teams_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: teams_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE teams_id_seq OWNED BY teams.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE users (
    id integer NOT NULL,
    team_id integer NOT NULL,
    email character varying(255) NOT NULL,
    username character varying(20) NOT NULL,
    first_name character varying(255),
    last_name character varying(255),
    time_zone character varying(255) NOT NULL,
    password_hash character varying(255) NOT NULL,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    role user_role DEFAULT 'MEMBER'::user_role NOT NULL,
    state user_state DEFAULT 'ACTIVE'::user_state NOT NULL
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- Name: invitations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY invitations ALTER COLUMN id SET DEFAULT nextval('invitations_id_seq'::regclass);


--
-- Name: teams id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY teams ALTER COLUMN id SET DEFAULT nextval('teams_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- Name: invitations invitations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY invitations
    ADD CONSTRAINT invitations_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: teams teams_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY teams
    ADD CONSTRAINT teams_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: invitations_invitor_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX invitations_invitor_id_index ON invitations USING btree (invitor_id);


--
-- Name: invitations_team_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX invitations_team_id_index ON invitations USING btree (team_id);


--
-- Name: invitations_token_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX invitations_token_index ON invitations USING btree (token);


--
-- Name: invitations_unique_pending_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX invitations_unique_pending_email ON invitations USING btree (lower((email)::text)) WHERE (state = 'PENDING'::invitation_state);


--
-- Name: teams_slug_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX teams_slug_index ON teams USING btree (slug);


--
-- Name: users_team_id_email_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX users_team_id_email_index ON users USING btree (team_id, email);


--
-- Name: users_team_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX users_team_id_index ON users USING btree (team_id);


--
-- Name: users_team_id_username_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX users_team_id_username_index ON users USING btree (team_id, username);


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
-- Name: invitations invitations_team_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY invitations
    ADD CONSTRAINT invitations_team_id_fkey FOREIGN KEY (team_id) REFERENCES teams(id);


--
-- Name: users users_team_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_team_id_fkey FOREIGN KEY (team_id) REFERENCES teams(id);


--
-- PostgreSQL database dump complete
--

INSERT INTO "schema_migrations" (version) VALUES (20170527220454), (20170528000152), (20170715050656), (20170723211950), (20170723212331);

