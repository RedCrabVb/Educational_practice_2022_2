--
-- PostgreSQL database dump
--

-- Dumped from database version 14.2 (Debian 14.2-1.pgdg110+1)
-- Dumped by pg_dump version 14.1

-- Started on 2022-05-20 11:57:41

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
-- TOC entry 223 (class 1255 OID 42367)
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
    user_id integer,
    transfer_account character varying(255) NOT NULL
);


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
-- TOC entry 3389 (class 0 OID 0)
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
-- TOC entry 3390 (class 0 OID 0)
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
    use_session_id integer
);


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
-- TOC entry 3391 (class 0 OID 0)
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
    user_id integer NOT NULL,
    financial_products_id integer,
    open_date date NOT NULL,
    close_date date NOT NULL
);


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
-- TOC entry 3392 (class 0 OID 0)
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
-- TOC entry 3393 (class 0 OID 0)
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
    session_id integer NOT NULL,
    user_id integer,
    expiration_date date,
    last_active timestamp without time zone,
    value_session character varying(255) NOT NULL,
    device_information character varying(255)
);


--
-- TOC entry 222 (class 1259 OID 42345)
-- Name: user_session_session_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_session_session_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3394 (class 0 OID 0)
-- Dependencies: 222
-- Name: user_session_session_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_session_session_id_seq OWNED BY public.user_session.session_id;


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
-- TOC entry 3395 (class 0 OID 0)
-- Dependencies: 219
-- Name: user_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_user_id_seq OWNED BY public."user".user_id;


--
-- TOC entry 3203 (class 2604 OID 42325)
-- Name: account_transactions account_transactions_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_transactions ALTER COLUMN account_transactions_id SET DEFAULT nextval('public.account_transactions_account_transactions_id_seq'::regclass);


--
-- TOC entry 3198 (class 2604 OID 42275)
-- Name: financial_products financial_products_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.financial_products ALTER COLUMN financial_products_id SET DEFAULT nextval('public.financial_products_id_seq'::regclass);


--
-- TOC entry 3206 (class 2604 OID 42323)
-- Name: history_active_user history_active_user_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.history_active_user ALTER COLUMN history_active_user_id SET DEFAULT nextval('public.history_active_user_history_active_user_id_seq'::regclass);


--
-- TOC entry 3199 (class 2604 OID 42284)
-- Name: status_financial_products status_financial_products_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.status_financial_products ALTER COLUMN status_financial_products_id SET DEFAULT nextval('public.status_financial_products_id_seq'::regclass);


--
-- TOC entry 3204 (class 2604 OID 42319)
-- Name: type_transactions type_transactions_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.type_transactions ALTER COLUMN type_transactions_id SET DEFAULT nextval('public.type_transactions_type_transactions_id_seq'::regclass);


--
-- TOC entry 3202 (class 2604 OID 42321)
-- Name: user user_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."user" ALTER COLUMN user_id SET DEFAULT nextval('public.user_user_id_seq'::regclass);


--
-- TOC entry 3205 (class 2604 OID 42346)
-- Name: user_session session_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_session ALTER COLUMN session_id SET DEFAULT nextval('public.user_session_session_id_seq'::regclass);


--
-- TOC entry 3375 (class 0 OID 42294)
-- Dependencies: 214
-- Data for Name: account_transactions; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- TOC entry 3371 (class 0 OID 42272)
-- Dependencies: 210
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
-- TOC entry 3378 (class 0 OID 42309)
-- Dependencies: 217
-- Data for Name: history_active_user; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.history_active_user (history_active_user_id, last_active, use_session_id) VALUES (1, '2023-05-20 10:28:54', 1);
INSERT INTO public.history_active_user (history_active_user_id, last_active, use_session_id) VALUES (2, '2020-12-20 10:28:54', 1);


--
-- TOC entry 3373 (class 0 OID 42281)
-- Dependencies: 212
-- Data for Name: status_financial_products; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.status_financial_products (status_financial_products_id, user_id, financial_products_id, open_date, close_date) VALUES (2, 1, 2, '2022-05-01', '2023-05-13');
INSERT INTO public.status_financial_products (status_financial_products_id, user_id, financial_products_id, open_date, close_date) VALUES (3, 3, 8, '2020-05-09', '2022-05-07');


--
-- TOC entry 3376 (class 0 OID 42297)
-- Dependencies: 215
-- Data for Name: type_transactions; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.type_transactions (type_transactions_id, name) VALUES (1, 'debiting');
INSERT INTO public.type_transactions (type_transactions_id, name) VALUES (2, 'replenishment');
INSERT INTO public.type_transactions (type_transactions_id, name) VALUES (3, 'translation');


--
-- TOC entry 3374 (class 0 OID 42287)
-- Dependencies: 213
-- Data for Name: user; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public."user" (user_id, first_name, last_name, patronymic, phone, mail, passport, salt, hash_password, amount, currency) VALUES (1, 'Быков', 'Евгений', 'Леонидович', '+7 (971) 458-28-72', 'evgeniy12041980@mail.ru', 1923, 45, 34534534, 1000, 'RUB');
INSERT INTO public."user" (user_id, first_name, last_name, patronymic, phone, mail, passport, salt, hash_password, amount, currency) VALUES (2, 'Чудин', 'Бронислав ', 'Романович', '+7 (907) 300-81-95', 'BronislavChudin25@yandex.ru', 1823, 54, 45645645, 0, 'RUB');
INSERT INTO public."user" (user_id, first_name, last_name, patronymic, phone, mail, passport, salt, hash_password, amount, currency) VALUES (3, 'Конягин ', 'Эрнст ', 'Андреевич', '+7 (931) 031-43-89', 'ErnstKonyagin290@mail.ru', 3453, 23, 6645645, 0, 'RUB');
INSERT INTO public."user" (user_id, first_name, last_name, patronymic, phone, mail, passport, salt, hash_password, amount, currency) VALUES (4, 'Ленский ', 'Станимир ', 'Владимирович', '+7 (914) 472-21-68', 'StanimirLenskiy428@mail.ru', 6454, 54, 345345, 0, 'RUB');
INSERT INTO public."user" (user_id, first_name, last_name, patronymic, phone, mail, passport, salt, hash_password, amount, currency) VALUES (5, 'Сомова ', 'Борислава ', 'Эдуардовна', '+7 (985) 071-70-76', 'BorislavaSomova234@yandex.com', 3434, 65, 23423432, 0, 'RUB');


--
-- TOC entry 3377 (class 0 OID 42306)
-- Dependencies: 216
-- Data for Name: user_session; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.user_session (session_id, user_id, expiration_date, last_active, value_session, device_information) VALUES (1, 1, '2022-05-29', '2020-12-20 10:28:54', 'av45g45gsdf', NULL);


--
-- TOC entry 3396 (class 0 OID 0)
-- Dependencies: 221
-- Name: account_transactions_account_transactions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.account_transactions_account_transactions_id_seq', 1, false);


--
-- TOC entry 3397 (class 0 OID 0)
-- Dependencies: 209
-- Name: financial_products_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.financial_products_id_seq', 10, true);


--
-- TOC entry 3398 (class 0 OID 0)
-- Dependencies: 220
-- Name: history_active_user_history_active_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.history_active_user_history_active_user_id_seq', 2, true);


--
-- TOC entry 3399 (class 0 OID 0)
-- Dependencies: 211
-- Name: status_financial_products_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.status_financial_products_id_seq', 3, true);


--
-- TOC entry 3400 (class 0 OID 0)
-- Dependencies: 218
-- Name: type_transactions_type_transactions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.type_transactions_type_transactions_id_seq', 1, false);


--
-- TOC entry 3401 (class 0 OID 0)
-- Dependencies: 222
-- Name: user_session_session_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.user_session_session_id_seq', 1, true);


--
-- TOC entry 3402 (class 0 OID 0)
-- Dependencies: 219
-- Name: user_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.user_user_id_seq', 5, true);


--
-- TOC entry 3214 (class 2606 OID 42317)
-- Name: account_transactions account_transactions_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_transactions
    ADD CONSTRAINT account_transactions_pk PRIMARY KEY (account_transactions_id);


--
-- TOC entry 3208 (class 2606 OID 42279)
-- Name: financial_products financial_products_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.financial_products
    ADD CONSTRAINT financial_products_pk PRIMARY KEY (financial_products_id);


--
-- TOC entry 3223 (class 2606 OID 42313)
-- Name: history_active_user history_active_user_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.history_active_user
    ADD CONSTRAINT history_active_user_pk PRIMARY KEY (history_active_user_id);


--
-- TOC entry 3210 (class 2606 OID 42286)
-- Name: status_financial_products status_financial_products_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.status_financial_products
    ADD CONSTRAINT status_financial_products_pk PRIMARY KEY (status_financial_products_id);


--
-- TOC entry 3217 (class 2606 OID 42301)
-- Name: type_transactions type_transactions_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.type_transactions
    ADD CONSTRAINT type_transactions_pk PRIMARY KEY (type_transactions_id);


--
-- TOC entry 3212 (class 2606 OID 42293)
-- Name: user user_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public."user"
    ADD CONSTRAINT user_pk PRIMARY KEY (user_id);


--
-- TOC entry 3219 (class 2606 OID 42348)
-- Name: user_session user_session_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_session
    ADD CONSTRAINT user_session_pk PRIMARY KEY (session_id);


--
-- TOC entry 3215 (class 1259 OID 42302)
-- Name: type_transactions_name_uindex; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX type_transactions_name_uindex ON public.type_transactions USING btree (name);


--
-- TOC entry 3220 (class 1259 OID 42344)
-- Name: user_session_session_id_uindex; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX user_session_session_id_uindex ON public.user_session USING btree (session_id);


--
-- TOC entry 3221 (class 1259 OID 42364)
-- Name: user_session_value_uindex; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX user_session_value_uindex ON public.user_session USING btree (value_session);


--
-- TOC entry 3230 (class 2620 OID 42368)
-- Name: user_session save_history_active_after; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER save_history_active_after AFTER UPDATE ON public.user_session FOR EACH ROW EXECUTE FUNCTION public.save_history_active();


--
-- TOC entry 3226 (class 2606 OID 42326)
-- Name: account_transactions account_transactions_type_transactions_type_transactions_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_transactions
    ADD CONSTRAINT account_transactions_type_transactions_type_transactions_id_fk FOREIGN KEY (account_transactions_id) REFERENCES public.type_transactions(type_transactions_id);


--
-- TOC entry 3227 (class 2606 OID 42359)
-- Name: account_transactions account_transactions_user_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_transactions
    ADD CONSTRAINT account_transactions_user_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(user_id);


--
-- TOC entry 3229 (class 2606 OID 42349)
-- Name: history_active_user history_active_user_user_session_session_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.history_active_user
    ADD CONSTRAINT history_active_user_user_session_session_id_fk FOREIGN KEY (use_session_id) REFERENCES public.user_session(session_id);


--
-- TOC entry 3225 (class 2606 OID 42354)
-- Name: status_financial_products status_financial_products_financial_products_financial_products; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.status_financial_products
    ADD CONSTRAINT status_financial_products_financial_products_financial_products FOREIGN KEY (financial_products_id) REFERENCES public.financial_products(financial_products_id);


--
-- TOC entry 3224 (class 2606 OID 42339)
-- Name: status_financial_products status_financial_products_user_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.status_financial_products
    ADD CONSTRAINT status_financial_products_user_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(user_id);


--
-- TOC entry 3228 (class 2606 OID 42334)
-- Name: user_session user_session_user_user_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_session
    ADD CONSTRAINT user_session_user_user_id_fk FOREIGN KEY (user_id) REFERENCES public."user"(user_id);


-- Completed on 2022-05-20 11:57:41

--
-- PostgreSQL database dump complete
--

