--
-- PostgreSQL database dump
--

-- Dumped from database version 14.2 (Debian 14.2-1.pgdg110+1)
-- Dumped by pg_dump version 14.1

-- Started on 2022-05-19 17:09:31

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
-- TOC entry 3 (class 2615 OID 2200)
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA public;


--
-- TOC entry 3375 (class 0 OID 0)
-- Dependencies: 3
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA public IS 'standard public schema';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 214 (class 1259 OID 42294)
-- Name: account_transactions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.account_transactions (
    account_transactions_id integer NOT NULL,
    type_transactions_id integer,
    amount integer NOT NULL,
    currency character varying(100) NOT NULL,
    user_id integer
);


--
-- TOC entry 3376 (class 0 OID 0)
-- Dependencies: 214
-- Name: TABLE account_transactions; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.account_transactions IS 'операции по счету';


--
-- TOC entry 221 (class 1259 OID 42324)
-- Name: account_transactions_account_transactions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.account_transactions_account_transactions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3377 (class 0 OID 0)
-- Dependencies: 221
-- Name: account_transactions_account_transactions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.account_transactions_account_transactions_id_seq OWNED BY public.account_transactions.account_transactions_id;


--
-- TOC entry 210 (class 1259 OID 42272)
-- Name: financial_products; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.financial_products (
    financial_products_id integer NOT NULL,
    title character varying(255) NOT NULL,
    description text NOT NULL
);


--
-- TOC entry 3378 (class 0 OID 0)
-- Dependencies: 210
-- Name: TABLE financial_products; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.financial_products IS 'Финансовые продукты';


--
-- TOC entry 209 (class 1259 OID 42271)
-- Name: financial_products_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.financial_products_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3379 (class 0 OID 0)
-- Dependencies: 209
-- Name: financial_products_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.financial_products_id_seq OWNED BY public.financial_products.financial_products_id;


--
-- TOC entry 217 (class 1259 OID 42309)
-- Name: history_active_user; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.history_active_user (
    history_active_user_id integer NOT NULL,
    last_active timestamp without time zone,
    use_session_id integer,
    device_information character varying(255)
);


--
-- TOC entry 3380 (class 0 OID 0)
-- Dependencies: 217
-- Name: TABLE history_active_user; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.history_active_user IS 'История использования ЛК';


--
-- TOC entry 220 (class 1259 OID 42322)
-- Name: history_active_user_history_active_user_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.history_active_user_history_active_user_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3381 (class 0 OID 0)
-- Dependencies: 220
-- Name: history_active_user_history_active_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.history_active_user_history_active_user_id_seq OWNED BY public.history_active_user.history_active_user_id;


--
-- TOC entry 212 (class 1259 OID 42281)
-- Name: status_financial_products; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.status_financial_products (
    status_financial_products_id integer NOT NULL,
    id_user integer,
    financial_products_id integer,
    open_date date NOT NULL,
    close_date date NOT NULL
);


--
-- TOC entry 3382 (class 0 OID 0)
-- Dependencies: 212
-- Name: TABLE status_financial_products; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.status_financial_products IS 'Статус финансовых продуктов';


--
-- TOC entry 211 (class 1259 OID 42280)
-- Name: status_financial_products_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.status_financial_products_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3383 (class 0 OID 0)
-- Dependencies: 211
-- Name: status_financial_products_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.status_financial_products_id_seq OWNED BY public.status_financial_products.status_financial_products_id;


--
-- TOC entry 215 (class 1259 OID 42297)
-- Name: type_transactions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.type_transactions (
    type_transactions_id integer NOT NULL,
    name character varying(255)
);


--
-- TOC entry 3384 (class 0 OID 0)
-- Dependencies: 215
-- Name: TABLE type_transactions; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.type_transactions IS 'Тип транзакций';


--
-- TOC entry 218 (class 1259 OID 42318)
-- Name: type_transactions_type_transactions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.type_transactions_type_transactions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3385 (class 0 OID 0)
-- Dependencies: 218
-- Name: type_transactions_type_transactions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.type_transactions_type_transactions_id_seq OWNED BY public.type_transactions.type_transactions_id;


--
-- TOC entry 213 (class 1259 OID 42287)
-- Name: user; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public."user" (
    user_id integer NOT NULL,
    first_name character varying(255) NOT NULL,
    last_name character varying(255) NOT NULL,
    patronymic character varying(255) NOT NULL,
    phone character varying(255) NOT NULL,
    mail character varying(255),
    passport integer,
    salt integer,
    hash_password integer,
    amount integer DEFAULT 0 NOT NULL,
    currency character varying(255) DEFAULT 'RUB'::character varying NOT NULL
);


--
-- TOC entry 216 (class 1259 OID 42306)
-- Name: user_session; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_session (
    session_id integer,
    user_id integer,
    expiration_date date,
    last_active timestamp without time zone
);


--
-- TOC entry 219 (class 1259 OID 42320)
-- Name: user_user_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_user_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3386 (class 0 OID 0)
-- Dependencies: 219
-- Name: user_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_user_id_seq OWNED BY public."user".user_id;


--
-- TOC entry 3201 (class 2604 OID 42325)
-- Name: account_transactions account_transactions_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_transactions ALTER COLUMN account_transactions_id SET DEFAULT nextval('public.account_transactions_account_transactions_id_seq'::regclass);


--
-- TOC entry 3196 (class 2604 OID 42275)
-- Name: financial_products financial_products_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.financial_products ALTER COLUMN financial_products_id SET DEFAULT nextval('public.financial_products_id_seq'::regclass);


--
-- TOC entry 3203 (class 2604 OID 42323)
-- Name: history_active_user history_active_user_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.history_active_user ALTER COLUMN history_active_user_id SET DEFAULT nextval('public.history_active_user_history_active_user_id_seq'::regclass);


--
-- TOC entry 3197 (class 2604 OID 42284)
-- Name: status_financial_products status_financial_products_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.status_financial_products ALTER COLUMN status_financial_products_id SET DEFAULT nextval('public.status_financial_products_id_seq'::regclass);


--
-- TOC entry 3202 (class 2604 OID 42319)
-- Name: type_transactions type_transactions_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.type_transactions ALTER COLUMN type_transactions_id SET DEFAULT nextval('public.type_transactions_type_transactions_id_seq'::regclass);


--
-- TOC entry 3200 (class 2604 OID 42321)
-- Name: user user_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."user" ALTER COLUMN user_id SET DEFAULT nextval('public.user_user_id_seq'::regclass);


--
-- TOC entry 3362 (class 0 OID 42294)
-- Dependencies: 214
-- Data for Name: account_transactions; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- TOC entry 3358 (class 0 OID 42272)
-- Dependencies: 210
-- Data for Name: financial_products; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- TOC entry 3365 (class 0 OID 42309)
-- Dependencies: 217
-- Data for Name: history_active_user; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- TOC entry 3360 (class 0 OID 42281)
-- Dependencies: 212
-- Data for Name: status_financial_products; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- TOC entry 3363 (class 0 OID 42297)
-- Dependencies: 215
-- Data for Name: type_transactions; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.type_transactions (type_transactions_id, name) VALUES (1, 'debiting');
INSERT INTO public.type_transactions (type_transactions_id, name) VALUES (2, 'replenishment');
INSERT INTO public.type_transactions (type_transactions_id, name) VALUES (3, 'translation');


--
-- TOC entry 3361 (class 0 OID 42287)
-- Dependencies: 213
-- Data for Name: user; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public."user" (user_id, first_name, last_name, patronymic, phone, mail, passport, salt, hash_password, amount, currency) VALUES (1, 'Быков', 'Евгений', 'Леонидович', '+7 (971) 458-28-72', 'evgeniy12041980@mail.ru', 1923, 45, 34534534, 1000, 'RUB');


--
-- TOC entry 3364 (class 0 OID 42306)
-- Dependencies: 216
-- Data for Name: user_session; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- TOC entry 3387 (class 0 OID 0)
-- Dependencies: 221
-- Name: account_transactions_account_transactions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.account_transactions_account_transactions_id_seq', 1, false);


--
-- TOC entry 3388 (class 0 OID 0)
-- Dependencies: 209
-- Name: financial_products_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.financial_products_id_seq', 1, false);


--
-- TOC entry 3389 (class 0 OID 0)
-- Dependencies: 220
-- Name: history_active_user_history_active_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.history_active_user_history_active_user_id_seq', 1, false);


--
-- TOC entry 3390 (class 0 OID 0)
-- Dependencies: 211
-- Name: status_financial_products_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.status_financial_products_id_seq', 1, false);


--
-- TOC entry 3391 (class 0 OID 0)
-- Dependencies: 218
-- Name: type_transactions_type_transactions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.type_transactions_type_transactions_id_seq', 1, false);


--
-- TOC entry 3392 (class 0 OID 0)
-- Dependencies: 219
-- Name: user_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.user_user_id_seq', 1, true);


--
-- TOC entry 3211 (class 2606 OID 42317)
-- Name: account_transactions account_transactions_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_transactions
    ADD CONSTRAINT account_transactions_pk PRIMARY KEY (account_transactions_id);


--
-- TOC entry 3205 (class 2606 OID 42279)
-- Name: financial_products financial_products_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.financial_products
    ADD CONSTRAINT financial_products_pk PRIMARY KEY (financial_products_id);


--
-- TOC entry 3216 (class 2606 OID 42313)
-- Name: history_active_user history_active_user_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.history_active_user
    ADD CONSTRAINT history_active_user_pk PRIMARY KEY (history_active_user_id);


--
-- TOC entry 3207 (class 2606 OID 42286)
-- Name: status_financial_products status_financial_products_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.status_financial_products
    ADD CONSTRAINT status_financial_products_pk PRIMARY KEY (status_financial_products_id);


--
-- TOC entry 3214 (class 2606 OID 42301)
-- Name: type_transactions type_transactions_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.type_transactions
    ADD CONSTRAINT type_transactions_pk PRIMARY KEY (type_transactions_id);


--
-- TOC entry 3209 (class 2606 OID 42293)
-- Name: user user_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."user"
    ADD CONSTRAINT user_pk PRIMARY KEY (user_id);


--
-- TOC entry 3212 (class 1259 OID 42302)
-- Name: type_transactions_name_uindex; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX type_transactions_name_uindex ON public.type_transactions USING btree (name);


--
-- TOC entry 3217 (class 2606 OID 42326)
-- Name: account_transactions account_transactions_type_transactions_type_transactions_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_transactions
    ADD CONSTRAINT account_transactions_type_transactions_type_transactions_id_fk FOREIGN KEY (account_transactions_id) REFERENCES public.type_transactions(type_transactions_id);


-- Completed on 2022-05-19 17:09:31

--
-- PostgreSQL database dump complete
--

