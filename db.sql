--
-- PostgreSQL database dump
--

-- Dumped from database version 14.2 (Debian 14.2-1.pgdg110+1)
-- Dumped by pg_dump version 14.1

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
-- Name: account_transactions_period(date, date); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.account_transactions_period(date_first date, date_second date) RETURNS TABLE(amount integer, user_id integer, date date)
    LANGUAGE plpgsql
    AS $$declare
begin
    RETURN QUERY
        select a_t.amount, a_t.user_id, a_t.date from account_transactions a_t where a_t.date > date_first and a_t.date < date_second;
end;
$$;


--
-- Name: make_operation(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.make_operation() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    amount_user INT := (select amount from "user" where user_id = NEW.user_id);

BEGIN
    raise notice 'amount user = %', amount_user;
    IF NEW.type_transactions_id = 1 or NEW.type_transactions_id = 3 THEN
        update "user" set amount = amount_user - NEW.amount where user_id = NEW.user_id;
    ELSE IF NEW.type_transactions_id = 2 THEN
        update "user" set amount = amount_user + NEW.amount where user_id = NEW.user_id;
    end if;
    END IF;
    RETURN NEW;
END;
$$;


--
-- Name: save_history_active(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.save_history_active() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF new.last_active != old.last_active THEN
        insert into history_active_user (last_active, use_session_id) values (NEW.last_active, NEW.user_id);
    END IF;
    RETURN NEW;
END;
$$;


--
-- Name: account_transactions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.account_transactions (
    account_transactions_id integer NOT NULL,
    type_transactions_id integer,
    amount integer NOT NULL,
    currency character varying(100) NOT NULL,
    user_id integer,
    transfer_account character varying(255) NOT NULL,
    date date DEFAULT now()
)
PARTITION BY RANGE (account_transactions_id);


--
-- Name: TABLE account_transactions; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.account_transactions IS 'операции по счету';


--
-- Name: account_transactions_account_transactions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.account_transactions_account_transactions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: account_transactions_account_transactions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.account_transactions_account_transactions_id_seq OWNED BY public.account_transactions.account_transactions_id;


SET default_table_access_method = heap;

--
-- Name: account_transactions_0_to_10; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.account_transactions_0_to_10 (
    account_transactions_id integer DEFAULT nextval('public.account_transactions_account_transactions_id_seq'::regclass) NOT NULL,
    type_transactions_id integer,
    amount integer NOT NULL,
    currency character varying(100) NOT NULL,
    user_id integer,
    transfer_account character varying(255) NOT NULL,
    date date DEFAULT now()
);


--
-- Name: account_transactions_10_to_100; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.account_transactions_10_to_100 (
    account_transactions_id integer DEFAULT nextval('public.account_transactions_account_transactions_id_seq'::regclass) NOT NULL,
    type_transactions_id integer,
    amount integer NOT NULL,
    currency character varying(100) NOT NULL,
    user_id integer,
    transfer_account character varying(255) NOT NULL,
    date date DEFAULT now()
);


--
-- Name: financial_products; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.financial_products (
    financial_products_id integer NOT NULL,
    title character varying(255) NOT NULL,
    description text NOT NULL
);


--
-- Name: TABLE financial_products; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.financial_products IS 'Финансовые продукты';


--
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
-- Name: financial_products_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.financial_products_id_seq OWNED BY public.financial_products.financial_products_id;


--
-- Name: history_active_user; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.history_active_user (
    history_active_user_id integer NOT NULL,
    last_active timestamp without time zone,
    use_session_id integer
);


--
-- Name: TABLE history_active_user; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.history_active_user IS 'История использования ЛК';


--
-- Name: history_active_user_history_active_user_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.history_active_user_history_active_user_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: history_active_user_history_active_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.history_active_user_history_active_user_id_seq OWNED BY public.history_active_user.history_active_user_id;


--
-- Name: status_financial_products; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.status_financial_products (
    status_financial_products_id integer NOT NULL,
    user_id integer NOT NULL,
    financial_products_id integer,
    open_date date NOT NULL,
    close_date date NOT NULL
);


--
-- Name: TABLE status_financial_products; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.status_financial_products IS 'Статус финансовых продуктов';


--
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
-- Name: status_financial_products_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.status_financial_products_id_seq OWNED BY public.status_financial_products.status_financial_products_id;


--
-- Name: summary_information_about_the_client; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.summary_information_about_the_client AS
SELECT
    NULL::text AS fcs,
    NULL::text AS amount,
    NULL::timestamp without time zone AS lastactivitydate;


--
-- Name: t_note; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.t_note (
    id bigint NOT NULL,
    body text,
    head text,
    id_user bigint
);


--
-- Name: t_note_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.t_note_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: t_note_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.t_note_id_seq OWNED BY public.t_note.id;


--
-- Name: t_role; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.t_role (
    id bigint NOT NULL,
    name character varying(255)
);


--
-- Name: t_user; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.t_user (
    id bigint NOT NULL,
    email character varying(255),
    password character varying(255),
    login character varying(255)
);


--
-- Name: t_user_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.t_user_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: t_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.t_user_id_seq OWNED BY public.t_user.id;


--
-- Name: t_user_roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.t_user_roles (
    user_id bigint NOT NULL,
    roles_id bigint NOT NULL
);


--
-- Name: type_transactions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.type_transactions (
    type_transactions_id integer NOT NULL,
    name character varying(255)
);


--
-- Name: TABLE type_transactions; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.type_transactions IS 'Тип транзакций';


--
-- Name: type_transactions_type_transactions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.type_transactions_type_transactions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: type_transactions_type_transactions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.type_transactions_type_transactions_id_seq OWNED BY public.type_transactions.type_transactions_id;


--
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
-- Name: user_session; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_session (
    session_id integer NOT NULL,
    user_id integer,
    expiration_date date,
    last_active timestamp without time zone,
    value_session character varying(255) NOT NULL,
    device_information character varying(255)
);


--
-- Name: user_session_session_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_session_session_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_session_session_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_session_session_id_seq OWNED BY public.user_session.session_id;


--
-- Name: user_user_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_user_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_user_id_seq OWNED BY public."user".user_id;


--
-- Name: account_transactions_0_to_10; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_transactions ATTACH PARTITION public.account_transactions_0_to_10 FOR VALUES FROM (0) TO (10);


--
-- Name: account_transactions_10_to_100; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_transactions ATTACH PARTITION public.account_transactions_10_to_100 FOR VALUES FROM (10) TO (100);


--
-- Name: account_transactions account_transactions_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_transactions ALTER COLUMN account_transactions_id SET DEFAULT nextval('public.account_transactions_account_transactions_id_seq'::regclass);


--
-- Name: financial_products financial_products_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.financial_products ALTER COLUMN financial_products_id SET DEFAULT nextval('public.financial_products_id_seq'::regclass);


--
-- Name: history_active_user history_active_user_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.history_active_user ALTER COLUMN history_active_user_id SET DEFAULT nextval('public.history_active_user_history_active_user_id_seq'::regclass);


--
-- Name: status_financial_products status_financial_products_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.status_financial_products ALTER COLUMN status_financial_products_id SET DEFAULT nextval('public.status_financial_products_id_seq'::regclass);


--
-- Name: t_note id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.t_note ALTER COLUMN id SET DEFAULT nextval('public.t_note_id_seq'::regclass);


--
-- Name: t_user id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.t_user ALTER COLUMN id SET DEFAULT nextval('public.t_user_id_seq'::regclass);


--
-- Name: type_transactions type_transactions_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.type_transactions ALTER COLUMN type_transactions_id SET DEFAULT nextval('public.type_transactions_type_transactions_id_seq'::regclass);


--
-- Name: user user_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."user" ALTER COLUMN user_id SET DEFAULT nextval('public.user_user_id_seq'::regclass);


--
-- Name: user_session session_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_session ALTER COLUMN session_id SET DEFAULT nextval('public.user_session_session_id_seq'::regclass);


--
-- Data for Name: account_transactions_0_to_10; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.account_transactions_0_to_10 (account_transactions_id, type_transactions_id, amount, currency, user_id, transfer_account, date) VALUES (2, 1, 500, 'RUB', 1, '34534', '2016-05-29');
INSERT INTO public.account_transactions_0_to_10 (account_transactions_id, type_transactions_id, amount, currency, user_id, transfer_account, date) VALUES (1, 1, 900, 'RUB', 1, '23452', '2021-05-08');
INSERT INTO public.account_transactions_0_to_10 (account_transactions_id, type_transactions_id, amount, currency, user_id, transfer_account, date) VALUES (9, 1, 300, 'RUB', 2, '23345', '2022-05-05');


--
-- Data for Name: account_transactions_10_to_100; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.account_transactions_10_to_100 (account_transactions_id, type_transactions_id, amount, currency, user_id, transfer_account, date) VALUES (17, 2, 322, 'RUB', 1, '346', '2022-05-28');
INSERT INTO public.account_transactions_10_to_100 (account_transactions_id, type_transactions_id, amount, currency, user_id, transfer_account, date) VALUES (10, 2, 5000, 'RUB', 2, '345345', '2021-05-28');
INSERT INTO public.account_transactions_10_to_100 (account_transactions_id, type_transactions_id, amount, currency, user_id, transfer_account, date) VALUES (18, 2, 600, 'RUB', 3, '5656', '2021-05-14');
INSERT INTO public.account_transactions_10_to_100 (account_transactions_id, type_transactions_id, amount, currency, user_id, transfer_account, date) VALUES (15, 1, 555, 'RUB', 3, '345345', '2021-05-07');
INSERT INTO public.account_transactions_10_to_100 (account_transactions_id, type_transactions_id, amount, currency, user_id, transfer_account, date) VALUES (16, 2, 600, 'RUB', 4, '34534', '2022-07-21');
INSERT INTO public.account_transactions_10_to_100 (account_transactions_id, type_transactions_id, amount, currency, user_id, transfer_account, date) VALUES (14, 3, 100, 'RUB', 3, '534534', '2022-02-05');
INSERT INTO public.account_transactions_10_to_100 (account_transactions_id, type_transactions_id, amount, currency, user_id, transfer_account, date) VALUES (12, 1, 300, 'RUB', 1, '12345', '2022-04-08');


--
-- Data for Name: financial_products; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.financial_products (financial_products_id, title, description) VALUES (2, 'Ипотечный кредит', 'кредит под залог недвижимости');
INSERT INTO public.financial_products (financial_products_id, title, description) VALUES (3, 'Коммерческий кредит', 'Кредиты для бизнеса на любые цели');
INSERT INTO public.financial_products (financial_products_id, title, description) VALUES (4, 'Депозит', 'Сумма денег, переданная лицом кредитному учреждению с целью получить доход в виде процентов, образующихся в ходе финансовых операций с вкладом');
INSERT INTO public.financial_products (financial_products_id, title, description) VALUES (5, 'Вклад', 'Сумма денег, переданная лицом кредитному учреждению с целью получить доход в виде процентов, образующихся в ходе финансовых операций с вкладом.Пополнение
Снятие
до 9,07%');
INSERT INTO public.financial_products (financial_products_id, title, description) VALUES (6, 'Накопительный счёт', 'Копите и свободно распоряжайтесь деньгами — ежемесячное начисление процентов, возможность пополнять и снимать без ограничений. Для новых пользователей повышенная ставка.');
INSERT INTO public.financial_products (financial_products_id, title, description) VALUES (7, 'Акции', 'Документ, удостоверяющий, с соблюдением установленной формы и обязательных реквизитов, имущественные права, осуществление или передача которых возможны только при его предъявлении.');
INSERT INTO public.financial_products (financial_products_id, title, description) VALUES (8, 'Облигации', 'Эмиссионная долговая ценная бумага, владелец которой имеет право получить её номинальную стоимость деньгами или имуществом в установленный ею срок от того, кто её выпустил.');
INSERT INTO public.financial_products (financial_products_id, title, description) VALUES (9, 'Кредитная карта', 'Банковская платёжная карта, предназначенная для совершения операций, расчёты по которым осуществляются за счёт денежных средств, предоставленных банком клиенту в пределах установленного лимита в соответствии с условиями кредитного договора. ');
INSERT INTO public.financial_products (financial_products_id, title, description) VALUES (10, 'Дебетовая карта', 'Банковская платёжная карта, используемая для оплаты товаров и услуг, получения наличных денег в банкоматах.');


--
-- Data for Name: history_active_user; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.history_active_user (history_active_user_id, last_active, use_session_id) VALUES (1, '2023-05-20 10:28:54', 1);
INSERT INTO public.history_active_user (history_active_user_id, last_active, use_session_id) VALUES (2, '2020-12-20 10:28:54', 1);


--
-- Data for Name: status_financial_products; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.status_financial_products (status_financial_products_id, user_id, financial_products_id, open_date, close_date) VALUES (2, 1, 2, '2022-05-01', '2023-05-13');
INSERT INTO public.status_financial_products (status_financial_products_id, user_id, financial_products_id, open_date, close_date) VALUES (3, 3, 8, '2020-05-09', '2022-05-07');


--
-- Data for Name: t_note; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: t_role; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: t_user; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: t_user_roles; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: type_transactions; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.type_transactions (type_transactions_id, name) VALUES (1, 'debiting');
INSERT INTO public.type_transactions (type_transactions_id, name) VALUES (2, 'replenishment');
INSERT INTO public.type_transactions (type_transactions_id, name) VALUES (3, 'translation');


--
-- Data for Name: user; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public."user" (user_id, first_name, last_name, patronymic, phone, mail, passport, salt, hash_password, amount, currency) VALUES (2, 'Чудин', 'Бронислав ', 'Романович', '+7 (907) 300-81-95', 'BronislavChudin25@yandex.ru', 1823, 54, 45645645, 14100, 'RUB');
INSERT INTO public."user" (user_id, first_name, last_name, patronymic, phone, mail, passport, salt, hash_password, amount, currency) VALUES (4, 'Ленский ', 'Станимир ', 'Владимирович', '+7 (914) 472-21-68', 'StanimirLenskiy428@mail.ru', 6454, 54, 345345, 2955, 'RUB');
INSERT INTO public."user" (user_id, first_name, last_name, patronymic, phone, mail, passport, salt, hash_password, amount, currency) VALUES (3, 'Конягин ', 'Эрнст ', 'Андреевич', '+7 (931) 031-43-89', 'ErnstKonyagin290@mail.ru', 3453, 23, 6645645, -120, 'RUB');
INSERT INTO public."user" (user_id, first_name, last_name, patronymic, phone, mail, passport, salt, hash_password, amount, currency) VALUES (1, 'Быков', 'Евгений', 'Леонидович', '+7 (971) 458-28-72', 'evgeniy12041980@mail.ru', 1923, 45, 34534534, -4812, 'RUB');
INSERT INTO public."user" (user_id, first_name, last_name, patronymic, phone, mail, passport, salt, hash_password, amount, currency) VALUES (5, 'Сомова ', 'Борислава ', 'Эдуардовна', '+7 (985) 071-70-76', 'BorislavaSomova234@yandex.com', 3434, 65, 23423432, 1000, 'RUB');


--
-- Data for Name: user_session; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.user_session (session_id, user_id, expiration_date, last_active, value_session, device_information) VALUES (1, 1, '2022-05-29', '2020-12-20 10:28:54', 'av45g45gsdf', NULL);


--
-- Name: account_transactions_account_transactions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.account_transactions_account_transactions_id_seq', 1, false);


--
-- Name: financial_products_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.financial_products_id_seq', 10, true);


--
-- Name: history_active_user_history_active_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.history_active_user_history_active_user_id_seq', 2, true);


--
-- Name: status_financial_products_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.status_financial_products_id_seq', 3, true);


--
-- Name: t_note_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.t_note_id_seq', 1, false);


--
-- Name: t_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.t_user_id_seq', 1, false);


--
-- Name: type_transactions_type_transactions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.type_transactions_type_transactions_id_seq', 1, false);


--
-- Name: user_session_session_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.user_session_session_id_seq', 1, true);


--
-- Name: user_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.user_user_id_seq', 5, true);


--
-- Name: account_transactions account_transactions_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_transactions
    ADD CONSTRAINT account_transactions_pk PRIMARY KEY (account_transactions_id);


--
-- Name: account_transactions_0_to_10 account_transactions_0_to_10_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_transactions_0_to_10
    ADD CONSTRAINT account_transactions_0_to_10_pkey PRIMARY KEY (account_transactions_id);


--
-- Name: account_transactions_10_to_100 account_transactions_10_to_100_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_transactions_10_to_100
    ADD CONSTRAINT account_transactions_10_to_100_pkey PRIMARY KEY (account_transactions_id);


--
-- Name: financial_products financial_products_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.financial_products
    ADD CONSTRAINT financial_products_pk PRIMARY KEY (financial_products_id);


--
-- Name: history_active_user history_active_user_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.history_active_user
    ADD CONSTRAINT history_active_user_pk PRIMARY KEY (history_active_user_id);


--
-- Name: status_financial_products status_financial_products_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.status_financial_products
    ADD CONSTRAINT status_financial_products_pk PRIMARY KEY (status_financial_products_id);


--
-- Name: t_note t_note_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.t_note
    ADD CONSTRAINT t_note_pkey PRIMARY KEY (id);


--
-- Name: t_role t_role_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.t_role
    ADD CONSTRAINT t_role_pkey PRIMARY KEY (id);


--
-- Name: t_user t_user_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.t_user
    ADD CONSTRAINT t_user_pkey PRIMARY KEY (id);


--
-- Name: t_user_roles t_user_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.t_user_roles
    ADD CONSTRAINT t_user_roles_pkey PRIMARY KEY (user_id, roles_id);


--
-- Name: type_transactions type_transactions_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.type_transactions
    ADD CONSTRAINT type_transactions_pk PRIMARY KEY (type_transactions_id);


--
-- Name: user user_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."user"
    ADD CONSTRAINT user_pk PRIMARY KEY (user_id);


--
-- Name: user_session user_session_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_session
    ADD CONSTRAINT user_session_pk PRIMARY KEY (session_id);


--
-- Name: type_transactions_name_uindex; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX type_transactions_name_uindex ON public.type_transactions USING btree (name);


--
-- Name: user_session_session_id_uindex; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX user_session_session_id_uindex ON public.user_session USING btree (session_id);


--
-- Name: user_session_value_uindex; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX user_session_value_uindex ON public.user_session USING btree (value_session);


--
-- Name: account_transactions_0_to_10_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.account_transactions_pk ATTACH PARTITION public.account_transactions_0_to_10_pkey;


--
-- Name: account_transactions_10_to_100_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.account_transactions_pk ATTACH PARTITION public.account_transactions_10_to_100_pkey;


--
-- Name: summary_information_about_the_client _RETURN; Type: RULE; Schema: public; Owner: -
--

CREATE OR REPLACE VIEW public.summary_information_about_the_client AS
 SELECT ((((("user".first_name)::text || ' '::text) || ("user".last_name)::text) || ' '::text) || ("user".patronymic)::text) AS fcs,
    (("user".amount || ' '::text) || ("user".currency)::text) AS amount,
    max(us.last_active) AS lastactivitydate
   FROM (public."user"
     JOIN public.user_session us ON (("user".user_id = us.user_id)))
  GROUP BY "user".user_id;


--
-- Name: account_transactions make_operation_after; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER make_operation_after AFTER INSERT ON public.account_transactions FOR EACH ROW EXECUTE FUNCTION public.make_operation();


--
-- Name: user_session save_history_active_after; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER save_history_active_after AFTER UPDATE ON public.user_session FOR EACH ROW EXECUTE FUNCTION public.save_history_active();


--
-- Name: account_transactions account_transactions_type_transactions_type_transactions_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.account_transactions
    ADD CONSTRAINT account_transactions_type_transactions_type_transactions_id_fk FOREIGN KEY (type_transactions_id) REFERENCES public.type_transactions(type_transactions_id);


--
-- Name: account_transactions account_transactions_user_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.account_transactions
    ADD CONSTRAINT account_transactions_user_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(user_id);


--
-- Name: t_user_roles fkj47yp3hhtsoajht9793tbdrp4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.t_user_roles
    ADD CONSTRAINT fkj47yp3hhtsoajht9793tbdrp4 FOREIGN KEY (roles_id) REFERENCES public.t_role(id);


--
-- Name: t_user_roles fkpqntgokae5e703qb206xvfdk3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.t_user_roles
    ADD CONSTRAINT fkpqntgokae5e703qb206xvfdk3 FOREIGN KEY (user_id) REFERENCES public.t_user(id);


--
-- Name: history_active_user history_active_user_user_session_session_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.history_active_user
    ADD CONSTRAINT history_active_user_user_session_session_id_fk FOREIGN KEY (use_session_id) REFERENCES public.user_session(session_id);


--
-- Name: status_financial_products status_financial_products_financial_products_financial_products; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.status_financial_products
    ADD CONSTRAINT status_financial_products_financial_products_financial_products FOREIGN KEY (financial_products_id) REFERENCES public.financial_products(financial_products_id);


--
-- Name: status_financial_products status_financial_products_user_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.status_financial_products
    ADD CONSTRAINT status_financial_products_user_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(user_id);


--
-- Name: user_session user_session_user_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_session
    ADD CONSTRAINT user_session_user_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(user_id);


--
-- PostgreSQL database dump complete
--

