--
-- PostgreSQL database dump
--

-- Dumped from database version 9.6.2
-- Dumped by pg_dump version 9.6.2

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

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: pods; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE pods (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    state integer NOT NULL,
    slug character varying(63) NOT NULL,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: pods_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE pods_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pods_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE pods_id_seq OWNED BY pods.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE schema_migrations (
    version bigint NOT NULL,
    inserted_at timestamp without time zone
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE users (
    id integer NOT NULL,
    pod_id integer NOT NULL,
    state integer NOT NULL,
    role integer NOT NULL,
    email character varying(255) NOT NULL,
    username character varying(20) NOT NULL,
    first_name character varying(255),
    last_name character varying(255),
    time_zone character varying(255) NOT NULL,
    password_hash character varying(255) NOT NULL,
    inserted_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
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
-- Name: pods id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY pods ALTER COLUMN id SET DEFAULT nextval('pods_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- Name: pods pods_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY pods
    ADD CONSTRAINT pods_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: pods_slug_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX pods_slug_index ON pods USING btree (slug);


--
-- Name: users_pod_id_email_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX users_pod_id_email_index ON users USING btree (pod_id, email);


--
-- Name: users_pod_id_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX users_pod_id_index ON users USING btree (pod_id);


--
-- Name: users_pod_id_username_index; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX users_pod_id_username_index ON users USING btree (pod_id, username);


--
-- Name: users users_pod_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pod_id_fkey FOREIGN KEY (pod_id) REFERENCES pods(id);


--
-- PostgreSQL database dump complete
--

INSERT INTO "schema_migrations" (version) VALUES (20170527220454), (20170528000152);

