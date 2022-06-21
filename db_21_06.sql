--
-- PostgreSQL database dump
--

-- Dumped from database version 14.2 (Debian 14.2-1.pgdg110+1)
-- Dumped by pg_dump version 14.1

-- Started on 2022-06-21 11:27:39

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
-- TOC entry 241 (class 1255 OID 108014)
-- Name: account_transactions_period(date, date); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.account_transactions_period(date_first date, date_second date) RETURNS TABLE(amount integer, user_id bigint, date timestamp without time zone)
    LANGUAGE plpgsql
    AS $$
declare
begin
    RETURN QUERY
        select a_t.amount, a_t.t_user_id, a_t.date from public.t_account_transations a_t where a_t.date > date_first and a_t.date < date_second;
end;
$$;


--
-- TOC entry 244 (class 1255 OID 116227)
-- Name: create_partition_if_mot_exists_history_active(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.create_partition_if_mot_exists_history_active(date bigint) RETURNS void
    LANGUAGE plpgsql
    AS $$
    declare forDate date := to_date(to_char(TO_TIMESTAMP(date / 1000), 'DD/MM/YYYY HH24:MI:SS'), 'DD/MM/YYYY');
    declare monthStart date := date_trunc('month', forDate);
    declare monthEndExclusive date := monthStart + interval '1 month';
    declare tableName text := 't_history_active_user' || to_char(forDate, 'YYYYmm');
begin
    raise notice 'sql: %', 'create table ' || tableName || ' partition of t_history_active_user_master for values from ('
                           || extract(epoch from monthStart::timestamp) * 1000 || ') to ('
                           || extract(epoch from monthStart::timestamp) * 1000 || ')';
    if to_regclass(tableName) is null then
        execute 'create table ' || tableName || ' partition of t_history_active_user_master for values from ('
                           || extract(epoch from monthStart::timestamp) * 1000 || ') to ('
                           || extract(epoch from monthEndExclusive::timestamp) * 1000|| ')';
        execute 'create unique index on ' || tableName || ' (last_active, user_agent)';
    end if;
end;
$$;


--
-- TOC entry 243 (class 1255 OID 42371)
-- Name: make_operation(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.make_operation() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    amount_user INT := (select amount from t_user where id = NEW.t_user_id);

BEGIN
    raise notice 'amount user = %', amount_user;
    case NEW.type_transactions_type_transactions_id
        when 1 then
            update t_user set amount = amount_user - NEW.amount where id = NEW.t_user_id;
            insert into t_account_transations (transfer_account, amount, currency, date, type_transactions_type_transactions_id, t_user_id)
                values (new.t_user_id, new.amount, new.currency, new.date, 3, (select id from t_user where login = new.transfer_account));
        when 2 then
            update t_user set amount = amount_user - NEW.amount where id = NEW.t_user_id;
        when 3 then
            update t_user set amount = amount_user + NEW.amount where id = NEW.t_user_id;
        else
            raise notice 'not found type_transactions';
    end case;

    RETURN NEW;
END;
$$;


--
-- TOC entry 242 (class 1255 OID 42367)
-- Name: save_history_active(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.save_history_active() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF new.last_access_time != old.last_access_time and new.last_access_time - old.last_access_time > 120 THEN
        insert into t_history_active_user_master (last_active, use_session_id, user_agent, user_id)
         values (NEW.last_access_time, NEW.primary_id,
                 substr(encode((select attribute_bytes from spring_session_attributes
                    where session_primary_id = NEW.primary_id and attribute_name = 'user_agent'), 'escape'), 23),
                 (select id from t_user where login = old.principal_name));
    END IF;
    RETURN NEW;
END;
$$;


SET default_tablespace = '';

--
-- TOC entry 225 (class 1259 OID 116212)
-- Name: t_history_active_user_master; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.t_history_active_user_master (
    use_session_id character(36) NOT NULL,
    user_agent character varying(255),
    last_active bigint NOT NULL,
    user_id bigint
)
PARTITION BY RANGE (last_active);


--
-- TOC entry 229 (class 1259 OID 124418)
-- Name: history_active_user_simple; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.history_active_user_simple AS
 SELECT uuid_in((md5(((random())::text || (random())::text)))::cstring) AS uuid,
    t_history_active_user_win.user_id,
    t_history_active_user_win.user_agent,
    t_history_active_user_win.use_session_id,
    t_history_active_user_win.last_active
   FROM ( SELECT t_history_active_user.use_session_id,
            t_history_active_user.user_agent,
            t_history_active_user.last_active,
            t_history_active_user.user_id,
            lag(t_history_active_user.last_active) OVER (ORDER BY t_history_active_user.use_session_id, t_history_active_user.user_agent, t_history_active_user.last_active) AS next_last_active,
            lag(t_history_active_user.user_agent) OVER (ORDER BY t_history_active_user.use_session_id, t_history_active_user.user_agent, t_history_active_user.last_active) AS next_user_agent,
            lead(t_history_active_user.use_session_id) OVER (ORDER BY t_history_active_user.use_session_id, t_history_active_user.user_agent, t_history_active_user.last_active) AS prv_use_session_id
           FROM public.t_history_active_user_master t_history_active_user) t_history_active_user_win
  WHERE ((((t_history_active_user_win.next_last_active - 3600000) > t_history_active_user_win.last_active) OR (NOT ((t_history_active_user_win.next_user_agent)::text = (t_history_active_user_win.user_agent)::text)) OR (NOT (t_history_active_user_win.use_session_id = t_history_active_user_win.prv_use_session_id))) AND (NOT (t_history_active_user_win.user_agent IS NULL)))
  ORDER BY t_history_active_user_win.use_session_id, t_history_active_user_win.last_active;


SET default_table_access_method = heap;

--
-- TOC entry 211 (class 1259 OID 91616)
-- Name: spring_session; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.spring_session (
    primary_id character(36) NOT NULL,
    session_id character(36) NOT NULL,
    creation_time bigint NOT NULL,
    last_access_time bigint NOT NULL,
    max_inactive_interval integer NOT NULL,
    expiry_time bigint NOT NULL,
    principal_name character varying(100)
);


--
-- TOC entry 212 (class 1259 OID 91624)
-- Name: spring_session_attributes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.spring_session_attributes (
    session_primary_id character(36) NOT NULL,
    attribute_name character varying(200) NOT NULL,
    attribute_bytes bytea NOT NULL
);


--
-- TOC entry 228 (class 1259 OID 124414)
-- Name: summary_information_about_the_client; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.summary_information_about_the_client AS
SELECT
    NULL::text AS fcs,
    NULL::text AS amount,
    NULL::bigint AS lastactivitydate;


--
-- TOC entry 222 (class 1259 OID 91794)
-- Name: t_account_transations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.t_account_transations (
    account_transactions_id bigint NOT NULL,
    transfer_account character varying(255),
    amount integer NOT NULL,
    currency character varying(255),
    date timestamp without time zone,
    type_transactions_type_transactions_id bigint,
    t_user_id bigint
);


--
-- TOC entry 221 (class 1259 OID 91793)
-- Name: t_account_transations_account_transactions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.t_account_transations_account_transactions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3441 (class 0 OID 0)
-- Dependencies: 221
-- Name: t_account_transations_account_transactions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.t_account_transations_account_transactions_id_seq OWNED BY public.t_account_transations.account_transactions_id;


--
-- TOC entry 214 (class 1259 OID 91742)
-- Name: t_financial_products; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.t_financial_products (
    financial_products_id bigint NOT NULL,
    title character varying(255),
    description character varying(255)
);


--
-- TOC entry 213 (class 1259 OID 91741)
-- Name: t_financial_products_financial_products_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.t_financial_products_financial_products_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3442 (class 0 OID 0)
-- Dependencies: 213
-- Name: t_financial_products_financial_products_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.t_financial_products_financial_products_id_seq OWNED BY public.t_financial_products.financial_products_id;


--
-- TOC entry 227 (class 1259 OID 124391)
-- Name: t_history_active_user202203; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.t_history_active_user202203 (
    use_session_id character(36) NOT NULL,
    user_agent character varying(255),
    last_active bigint NOT NULL,
    user_id bigint
);


--
-- TOC entry 226 (class 1259 OID 124384)
-- Name: t_history_active_user202206; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.t_history_active_user202206 (
    use_session_id character(36) NOT NULL,
    user_agent character varying(255),
    last_active bigint NOT NULL,
    user_id bigint
);


--
-- TOC entry 209 (class 1259 OID 42287)
-- Name: t_old_user; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.t_old_user (
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
-- TOC entry 215 (class 1259 OID 91757)
-- Name: t_role; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.t_role (
    id bigint NOT NULL,
    name character varying(255)
);


--
-- TOC entry 224 (class 1259 OID 91803)
-- Name: t_status_financial_products; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.t_status_financial_products (
    status_financial_products_id bigint NOT NULL,
    close_date timestamp without time zone,
    open_date timestamp without time zone,
    financial_products_financial_products_id bigint,
    t_user_id bigint
);


--
-- TOC entry 223 (class 1259 OID 91802)
-- Name: t_status_financial_products_status_financial_products_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.t_status_financial_products_status_financial_products_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3443 (class 0 OID 0)
-- Dependencies: 223
-- Name: t_status_financial_products_status_financial_products_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.t_status_financial_products_status_financial_products_id_seq OWNED BY public.t_status_financial_products.status_financial_products_id;


--
-- TOC entry 217 (class 1259 OID 91763)
-- Name: t_type_transactions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.t_type_transactions (
    type_transactions_id bigint NOT NULL,
    name character varying(255)
);


--
-- TOC entry 216 (class 1259 OID 91762)
-- Name: t_type_transactions_type_transactions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.t_type_transactions_type_transactions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3444 (class 0 OID 0)
-- Dependencies: 216
-- Name: t_type_transactions_type_transactions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.t_type_transactions_type_transactions_id_seq OWNED BY public.t_type_transactions.type_transactions_id;


--
-- TOC entry 219 (class 1259 OID 91770)
-- Name: t_user; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.t_user (
    id bigint NOT NULL,
    login character varying(255),
    password character varying(255),
    currency character varying(255),
    first_name character varying(255),
    last_name character varying(255),
    mail character varying(255),
    passport character varying(255),
    patronymic character varying(255),
    phone character varying(255),
    amount integer
);


--
-- TOC entry 218 (class 1259 OID 91769)
-- Name: t_user_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.t_user_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3445 (class 0 OID 0)
-- Dependencies: 218
-- Name: t_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.t_user_id_seq OWNED BY public.t_user.id;


--
-- TOC entry 220 (class 1259 OID 91778)
-- Name: t_user_roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.t_user_roles (
    user_id bigint NOT NULL,
    roles_id bigint NOT NULL
);


--
-- TOC entry 210 (class 1259 OID 42320)
-- Name: user_user_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_user_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3446 (class 0 OID 0)
-- Dependencies: 210
-- Name: user_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_user_id_seq OWNED BY public.t_old_user.user_id;


--
-- TOC entry 3233 (class 0 OID 0)
-- Name: t_history_active_user202203; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.t_history_active_user_master ATTACH PARTITION public.t_history_active_user202203 FOR VALUES FROM ('1646092800000') TO ('1648771200000');


--
-- TOC entry 3232 (class 0 OID 0)
-- Name: t_history_active_user202206; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.t_history_active_user_master ATTACH PARTITION public.t_history_active_user202206 FOR VALUES FROM ('1654041600000') TO ('1656633600000');


--
-- TOC entry 3240 (class 2604 OID 91797)
-- Name: t_account_transations account_transactions_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.t_account_transations ALTER COLUMN account_transactions_id SET DEFAULT nextval('public.t_account_transations_account_transactions_id_seq'::regclass);


--
-- TOC entry 3237 (class 2604 OID 91745)
-- Name: t_financial_products financial_products_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.t_financial_products ALTER COLUMN financial_products_id SET DEFAULT nextval('public.t_financial_products_financial_products_id_seq'::regclass);


--
-- TOC entry 3236 (class 2604 OID 42321)
-- Name: t_old_user user_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.t_old_user ALTER COLUMN user_id SET DEFAULT nextval('public.user_user_id_seq'::regclass);


--
-- TOC entry 3241 (class 2604 OID 91806)
-- Name: t_status_financial_products status_financial_products_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.t_status_financial_products ALTER COLUMN status_financial_products_id SET DEFAULT nextval('public.t_status_financial_products_status_financial_products_id_seq'::regclass);


--
-- TOC entry 3238 (class 2604 OID 91766)
-- Name: t_type_transactions type_transactions_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.t_type_transactions ALTER COLUMN type_transactions_id SET DEFAULT nextval('public.t_type_transactions_type_transactions_id_seq'::regclass);


--
-- TOC entry 3239 (class 2604 OID 91773)
-- Name: t_user id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.t_user ALTER COLUMN id SET DEFAULT nextval('public.t_user_id_seq'::regclass);


--
-- TOC entry 3420 (class 0 OID 91616)
-- Dependencies: 211
-- Data for Name: spring_session; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- TOC entry 3421 (class 0 OID 91624)
-- Dependencies: 212
-- Data for Name: spring_session_attributes; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- TOC entry 3431 (class 0 OID 91794)
-- Dependencies: 222
-- Data for Name: t_account_transations; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.t_account_transations (account_transactions_id, transfer_account, amount, currency, date, type_transactions_type_transactions_id, t_user_id) VALUES (32, 'cany245mailru246300522', 10, 'RUB', '2022-06-16 15:08:35.036', 1, 13);
INSERT INTO public.t_account_transations (account_transactions_id, transfer_account, amount, currency, date, type_transactions_type_transactions_id, t_user_id) VALUES (33, '2342644593376', 6, 'RUB', '2022-06-16 15:11:06.067', 1, 15);
INSERT INTO public.t_account_transations (account_transactions_id, transfer_account, amount, currency, date, type_transactions_type_transactions_id, t_user_id) VALUES (34, '2342644593376', 6, 'RUB', '2022-06-16 15:11:06.067', 3, 15);
INSERT INTO public.t_account_transations (account_transactions_id, transfer_account, amount, currency, date, type_transactions_type_transactions_id, t_user_id) VALUES (40, 'cany245mailru246300522', 3, 'RUB', '2022-06-16 15:17:47.251', 1, 13);
INSERT INTO public.t_account_transations (account_transactions_id, transfer_account, amount, currency, date, type_transactions_type_transactions_id, t_user_id) VALUES (41, '13', 3, 'RUB', '2022-06-16 15:17:47.251', 3, 15);
INSERT INTO public.t_account_transations (account_transactions_id, transfer_account, amount, currency, date, type_transactions_type_transactions_id, t_user_id) VALUES (42, 'cany245mailru246300522', 9, 'RUB', '2022-06-16 15:18:12.313', 1, 13);
INSERT INTO public.t_account_transations (account_transactions_id, transfer_account, amount, currency, date, type_transactions_type_transactions_id, t_user_id) VALUES (43, '13', 9, 'RUB', '2022-06-16 15:18:12.313', 3, 15);
INSERT INTO public.t_account_transations (account_transactions_id, transfer_account, amount, currency, date, type_transactions_type_transactions_id, t_user_id) VALUES (44, 'cany245mailru246300522', 1, 'RUB', '2022-06-16 15:20:19.751', 1, 13);
INSERT INTO public.t_account_transations (account_transactions_id, transfer_account, amount, currency, date, type_transactions_type_transactions_id, t_user_id) VALUES (45, '13', 1, 'RUB', '2022-06-16 15:20:19.751', 3, 15);
INSERT INTO public.t_account_transations (account_transactions_id, transfer_account, amount, currency, date, type_transactions_type_transactions_id, t_user_id) VALUES (46, 'cany245mailru246300522', 1, 'RUB', '2022-06-16 15:22:25.324', 1, 13);
INSERT INTO public.t_account_transations (account_transactions_id, transfer_account, amount, currency, date, type_transactions_type_transactions_id, t_user_id) VALUES (47, '13', 1, 'RUB', '2022-06-16 15:22:25.324', 3, 15);
INSERT INTO public.t_account_transations (account_transactions_id, transfer_account, amount, currency, date, type_transactions_type_transactions_id, t_user_id) VALUES (48, 'cany245mailru246300522', 42, 'RUB', '2022-06-21 10:03:27.398', 1, 13);
INSERT INTO public.t_account_transations (account_transactions_id, transfer_account, amount, currency, date, type_transactions_type_transactions_id, t_user_id) VALUES (49, '13', 42, 'RUB', '2022-06-21 10:03:27.398', 3, 15);
INSERT INTO public.t_account_transations (account_transactions_id, transfer_account, amount, currency, date, type_transactions_type_transactions_id, t_user_id) VALUES (50, '2342644593376', 11, 'RUB', '2022-06-21 10:12:20.755', 1, 15);
INSERT INTO public.t_account_transations (account_transactions_id, transfer_account, amount, currency, date, type_transactions_type_transactions_id, t_user_id) VALUES (51, '15', 11, 'RUB', '2022-06-21 10:12:20.755', 3, 13);
INSERT INTO public.t_account_transations (account_transactions_id, transfer_account, amount, currency, date, type_transactions_type_transactions_id, t_user_id) VALUES (52, 'BronislavChudin25yandexru862695246', 3, 'RUB', '2022-06-21 11:08:26.467', 1, 16);
INSERT INTO public.t_account_transations (account_transactions_id, transfer_account, amount, currency, date, type_transactions_type_transactions_id, t_user_id) VALUES (53, '16', 3, 'RUB', '2022-06-21 11:08:26.467', 3, 16);
INSERT INTO public.t_account_transations (account_transactions_id, transfer_account, amount, currency, date, type_transactions_type_transactions_id, t_user_id) VALUES (54, 'BronislavChudin25yandexru862695246', 3, 'RUB', '2022-06-21 11:08:28.123', 1, 16);
INSERT INTO public.t_account_transations (account_transactions_id, transfer_account, amount, currency, date, type_transactions_type_transactions_id, t_user_id) VALUES (55, '16', 3, 'RUB', '2022-06-21 11:08:28.123', 3, 16);


--
-- TOC entry 3423 (class 0 OID 91742)
-- Dependencies: 214
-- Data for Name: t_financial_products; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.t_financial_products (financial_products_id, title, description) VALUES (2, 'Ипотечный кредит', 'кредит под залог недвижимости');
INSERT INTO public.t_financial_products (financial_products_id, title, description) VALUES (3, 'Коммерческий кредит', 'Кредиты для бизнеса на любые цели');
INSERT INTO public.t_financial_products (financial_products_id, title, description) VALUES (4, 'Депозит', 'Сумма денег, переданная лицом кредитному учреждению с целью получить доход в виде процентов, образующихся в ходе финансовых операций с вкладом');
INSERT INTO public.t_financial_products (financial_products_id, title, description) VALUES (5, 'Вклад', 'Сумма денег, переданная лицом кредитному учреждению с целью получить доход в виде процентов, образующихся в ходе финансовых операций с вкладом.Пополнение
Снятие
до 9,07%');
INSERT INTO public.t_financial_products (financial_products_id, title, description) VALUES (6, 'Накопительный счёт', 'Копите и свободно распоряжайтесь деньгами — ежемесячное начисление процентов, возможность пополнять и снимать без ограничений. Для новых пользователей повышенная ставка.');
INSERT INTO public.t_financial_products (financial_products_id, title, description) VALUES (7, 'Акции', 'Документ, удостоверяющий, с соблюдением установленной формы и обязательных реквизитов, имущественные права, осуществление или передача которых возможны только при его предъявлении.');
INSERT INTO public.t_financial_products (financial_products_id, title, description) VALUES (8, 'Облигации', 'Эмиссионная долговая ценная бумага, владелец которой имеет право получить её номинальную стоимость деньгами или имуществом в установленный ею срок от того, кто её выпустил.');
INSERT INTO public.t_financial_products (financial_products_id, title, description) VALUES (9, 'Кредитная карта', 'Банковская платёжная карта, предназначенная для совершения операций, расчёты по которым осуществляются за счёт денежных средств, предоставленных банком клиенту в пределах установленного лимита в соответствии с условиями кредитного договора. ');
INSERT INTO public.t_financial_products (financial_products_id, title, description) VALUES (10, 'Дебетовая карта', 'Банковская платёжная карта, используемая для оплаты товаров и услуг, получения наличных денег в банкоматах.');


--
-- TOC entry 3435 (class 0 OID 124391)
-- Dependencies: 227
-- Data for Name: t_history_active_user202203; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.t_history_active_user202203 (use_session_id, user_agent, last_active, user_id) VALUES ('a15e0a5f-aa7b-4cea-9112-bf3eabe33a90', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1646377715037, 14);
INSERT INTO public.t_history_active_user202203 (use_session_id, user_agent, last_active, user_id) VALUES ('a15e0a5f-aa7b-4cea-9112-bf3eabe33a90', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1646377718115, 14);
INSERT INTO public.t_history_active_user202203 (use_session_id, user_agent, last_active, user_id) VALUES ('396aa4d3-11ac-40b2-8e0c-6bdd1b63490e', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1646377720718, 14);
INSERT INTO public.t_history_active_user202203 (use_session_id, user_agent, last_active, user_id) VALUES ('396aa4d3-11ac-40b2-8e0c-6bdd1b63490e', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1646377989336, 14);
INSERT INTO public.t_history_active_user202203 (use_session_id, user_agent, last_active, user_id) VALUES ('2fb9fd4f-9767-4d51-a8e3-6a62e14c811f', NULL, 1646377996224, NULL);


--
-- TOC entry 3434 (class 0 OID 124384)
-- Dependencies: 226
-- Data for Name: t_history_active_user202206; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('a15e0a5f-aa7b-4cea-9112-bf3eabe33a90', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655377715037, 14);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('a15e0a5f-aa7b-4cea-9112-bf3eabe33a90', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655377718115, 14);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('396aa4d3-11ac-40b2-8e0c-6bdd1b63490e', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655377720718, 14);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('396aa4d3-11ac-40b2-8e0c-6bdd1b63490e', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655377989336, 14);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('2fb9fd4f-9767-4d51-a8e3-6a62e14c811f', NULL, 1655377996224, NULL);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('54c88287-c799-4c67-be72-02e6422824c5', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655377679404, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('396aa4d3-11ac-40b2-8e0c-6bdd1b63490e', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655377688834, 14);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('396aa4d3-11ac-40b2-8e0c-6bdd1b63490e', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655377689706, 14);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('8dfbdbc9-c4cb-4fa3-995f-e60a1b1ee9f4', NULL, 1655377706864, NULL);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('cd1c6aee-83a0-4c1c-a5ff-f2c273e997ed', NULL, 1655377707149, NULL);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('32dbb2bb-2b49-4fed-969a-99decb3b70a9', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655378006561, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('32dbb2bb-2b49-4fed-969a-99decb3b70a9', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655378031863, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('32dbb2bb-2b49-4fed-969a-99decb3b70a9', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655378146727, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('4c921e03-0760-437d-9967-331c6be74980', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655378219677, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('32dbb2bb-2b49-4fed-969a-99decb3b70a9', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655378463849, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655378483259, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655378688122, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655378693247, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655378695135, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655378750638, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655378753707, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('396aa4d3-11ac-40b2-8e0c-6bdd1b63490e', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655377686458, 14);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('396aa4d3-11ac-40b2-8e0c-6bdd1b63490e', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655377687417, 14);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('396aa4d3-11ac-40b2-8e0c-6bdd1b63490e', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655377689201, 14);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('8dfbdbc9-c4cb-4fa3-995f-e60a1b1ee9f4', NULL, 1655377707046, NULL);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('a15e0a5f-aa7b-4cea-9112-bf3eabe33a90', NULL, 1655377707190, NULL);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('396aa4d3-11ac-40b2-8e0c-6bdd1b63490e', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655377847337, 14);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('32dbb2bb-2b49-4fed-969a-99decb3b70a9', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655378144618, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('4c921e03-0760-437d-9967-331c6be74980', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655378221590, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('32dbb2bb-2b49-4fed-969a-99decb3b70a9', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655378467174, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655378499703, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655378677605, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655378685820, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655378691223, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655378712392, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('a15e0a5f-aa7b-4cea-9112-bf3eabe33a90', NULL, 1655377711756, NULL);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('a15e0a5f-aa7b-4cea-9112-bf3eabe33a90', NULL, 1655377711892, 14);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('396aa4d3-11ac-40b2-8e0c-6bdd1b63490e', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655377905061, 14);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('a15e0a5f-aa7b-4cea-9112-bf3eabe33a90', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655377915055, 14);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('2fb9fd4f-9767-4d51-a8e3-6a62e14c811f', NULL, 1655377996377, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('a15e0a5f-aa7b-4cea-9112-bf3eabe33a90', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655378017189, 14);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('4c921e03-0760-437d-9967-331c6be74980', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655378028409, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('4c921e03-0760-437d-9967-331c6be74980', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655378298317, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('a2f5185e-50ee-4abe-890f-b2f28282fb14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.5005.124 Safari/537.36 Edg/102.0.1245.41', 1655378349921, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('32dbb2bb-2b49-4fed-969a-99decb3b70a9', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655378392168, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('32dbb2bb-2b49-4fed-969a-99decb3b70a9', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655378465434, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('32dbb2bb-2b49-4fed-969a-99decb3b70a9', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655378466077, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('32dbb2bb-2b49-4fed-969a-99decb3b70a9', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655378469427, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655378484110, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655378689288, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655378700434, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655378751913, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('2fb9fd4f-9767-4d51-a8e3-6a62e14c811f', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655377999499, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('32dbb2bb-2b49-4fed-969a-99decb3b70a9', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655378143049, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('32dbb2bb-2b49-4fed-969a-99decb3b70a9', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655378213410, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('32dbb2bb-2b49-4fed-969a-99decb3b70a9', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655378215355, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('32dbb2bb-2b49-4fed-969a-99decb3b70a9', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655378468948, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('32dbb2bb-2b49-4fed-969a-99decb3b70a9', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655378470025, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655379961595, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655379967027, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('c42b8dfc-2f5b-4b33-a7f6-876e62260d63', NULL, 1655379991710, NULL);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655379962096, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655379964448, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('c42b8dfc-2f5b-4b33-a7f6-876e62260d63', NULL, 1655379989934, NULL);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655380024442, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655380029388, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('ba357942-7c70-4258-870d-0feea7c0e8dd', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655380040057, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655380292442, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655380297935, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655380032151, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655380046873, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655380033705, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655380429025, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655380430173, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655380431665, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655380432462, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655380446135, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655380566886, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655380626747, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('ba357942-7c70-4258-870d-0feea7c0e8dd', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655380631798, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655380634197, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655380637036, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655380641391, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('ba357942-7c70-4258-870d-0feea7c0e8dd', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655380895474, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655381077963, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655380431860, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655380431933, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655380449256, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655380450200, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('ba357942-7c70-4258-870d-0feea7c0e8dd', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655380579593, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655380722156, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('ba357942-7c70-4258-870d-0feea7c0e8dd', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655380883368, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655381081830, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655380444151, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('ba357942-7c70-4258-870d-0feea7c0e8dd', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655380577727, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655380617670, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655381073295, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('ba357942-7c70-4258-870d-0feea7c0e8dd', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655381085706, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655381088569, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655381091720, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('ba357942-7c70-4258-870d-0feea7c0e8dd', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655381098971, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655381106075, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('ba357942-7c70-4258-870d-0feea7c0e8dd', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655381108066, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655380569158, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655380570443, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('ba357942-7c70-4258-870d-0feea7c0e8dd', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655380575408, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('ba357942-7c70-4258-870d-0feea7c0e8dd', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655380582043, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('ba357942-7c70-4258-870d-0feea7c0e8dd', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655380622590, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655380628175, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655380635142, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('ba357942-7c70-4258-870d-0feea7c0e8dd', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655380644897, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655380649896, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655380653065, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655380897935, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('ba357942-7c70-4258-870d-0feea7c0e8dd', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655381097141, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655381101714, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655381111119, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655381112843, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655381171323, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655381177079, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655381178924, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('ba357942-7c70-4258-870d-0feea7c0e8dd', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655381187443, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('ba357942-7c70-4258-870d-0feea7c0e8dd', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655381189846, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655381179049, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('ba357942-7c70-4258-870d-0feea7c0e8dd', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655381192101, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('ba357942-7c70-4258-870d-0feea7c0e8dd', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655381202610, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655381223449, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655381280982, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('ba357942-7c70-4258-870d-0feea7c0e8dd', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655381312164, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655381476856, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655381477811, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655381508318, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655381521688, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655381663183, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('ba357942-7c70-4258-870d-0feea7c0e8dd', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655381666110, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('ba357942-7c70-4258-870d-0feea7c0e8dd', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655381780060, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655381787608, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655381790743, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655381870452, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('ba357942-7c70-4258-870d-0feea7c0e8dd', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655381885419, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655381895858, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('ba357942-7c70-4258-870d-0feea7c0e8dd', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655382006451, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('ba357942-7c70-4258-870d-0feea7c0e8dd', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655382142162, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('ba357942-7c70-4258-870d-0feea7c0e8dd', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655382153559, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655381221905, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655381305732, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655381319208, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655381360348, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655381464492, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('ba357942-7c70-4258-870d-0feea7c0e8dd', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655381469221, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('ba357942-7c70-4258-870d-0feea7c0e8dd', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655381472408, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655381475306, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655381480724, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('ba357942-7c70-4258-870d-0feea7c0e8dd', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655381515485, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655381543584, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('ba357942-7c70-4258-870d-0feea7c0e8dd', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655381555310, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655381651718, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('ba357942-7c70-4258-870d-0feea7c0e8dd', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655381657044, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655381789329, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655381898078, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655381948481, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655382035991, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655382149435, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('ba357942-7c70-4258-870d-0feea7c0e8dd', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655382154781, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655381291830, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655381317599, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('ba357942-7c70-4258-870d-0feea7c0e8dd', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655381473368, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655381479283, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655381540885, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('ba357942-7c70-4258-870d-0feea7c0e8dd', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655381690624, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('ba357942-7c70-4258-870d-0feea7c0e8dd', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655381793038, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('ba357942-7c70-4258-870d-0feea7c0e8dd', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655381881332, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('ba357942-7c70-4258-870d-0feea7c0e8dd', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655381883855, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('ba357942-7c70-4258-870d-0feea7c0e8dd', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655381890813, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('ba357942-7c70-4258-870d-0feea7c0e8dd', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655382004985, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655382032819, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655382148215, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('ba357942-7c70-4258-870d-0feea7c0e8dd', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655381322224, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('ba357942-7c70-4258-870d-0feea7c0e8dd', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655381459260, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('ba357942-7c70-4258-870d-0feea7c0e8dd', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655381546393, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('ba357942-7c70-4258-870d-0feea7c0e8dd', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655381550280, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655381662032, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('ba357942-7c70-4258-870d-0feea7c0e8dd', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655381671877, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655381872914, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('ba357942-7c70-4258-870d-0feea7c0e8dd', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655382009093, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('ba357942-7c70-4258-870d-0feea7c0e8dd', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655382013280, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655382034281, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655382151087, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('ba357942-7c70-4258-870d-0feea7c0e8dd', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655382156481, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655382196008, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655382198507, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655382290359, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655382291090, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655382291742, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655382292572, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('ba357942-7c70-4258-870d-0feea7c0e8dd', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655382331455, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('ba357942-7c70-4258-870d-0feea7c0e8dd', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655382347736, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655382382334, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('ba357942-7c70-4258-870d-0feea7c0e8dd', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655382418868, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('ba357942-7c70-4258-870d-0feea7c0e8dd', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655382426440, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('ba357942-7c70-4258-870d-0feea7c0e8dd', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655382351291, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655382356046, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('ba357942-7c70-4258-870d-0feea7c0e8dd', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655382361464, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('ba357942-7c70-4258-870d-0feea7c0e8dd', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655382383820, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('ba357942-7c70-4258-870d-0feea7c0e8dd', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655382425424, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655382467834, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655382376629, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('3e732268-600d-4549-bc81-f515ce0c1791', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655382380719, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('ba357942-7c70-4258-870d-0feea7c0e8dd', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655382386644, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('ba357942-7c70-4258-870d-0feea7c0e8dd', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655382423928, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('ba357942-7c70-4258-870d-0feea7c0e8dd', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655382419496, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('5f980a0c-8408-4797-b965-6bb34229836b', NULL, 1655374827324, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('5f980a0c-8408-4797-b965-6bb34229836b', NULL, 1655374827507, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('54c88287-c799-4c67-be72-02e6422824c5', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655377582799, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('54c88287-c799-4c67-be72-02e6422824c5', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655377583028, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('54c88287-c799-4c67-be72-02e6422824c5', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655377583116, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('54c88287-c799-4c67-be72-02e6422824c5', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655377583197, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('a15e0a5f-aa7b-4cea-9112-bf3eabe33a90', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655376815037, 14);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('a15e0a5f-aa7b-4cea-9112-bf3eabe33a90', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655376818115, 14);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('396aa4d3-11ac-40b2-8e0c-6bdd1b63490e', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655376820718, 14);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('396aa4d3-11ac-40b2-8e0c-6bdd1b63490e', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655377089336, 14);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('2fb9fd4f-9767-4d51-a8e3-6a62e14c811f', NULL, 1655377096224, NULL);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('a15e0a5f-aa7b-4cea-9112-bf3eabe33a90', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655287715037, 14);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('a15e0a5f-aa7b-4cea-9112-bf3eabe33a90', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655287718115, 14);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('396aa4d3-11ac-40b2-8e0c-6bdd1b63490e', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655287720718, 14);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('396aa4d3-11ac-40b2-8e0c-6bdd1b63490e', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655287989336, 14);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('2fb9fd4f-9767-4d51-a8e3-6a62e14c811f', NULL, 1655287996224, NULL);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('0a93a571-e1bd-4a1b-a974-ec6e6fa8c860', NULL, 1655794871224, NULL);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('0a93a571-e1bd-4a1b-a974-ec6e6fa8c860', NULL, 1655794871879, NULL);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('0a93a571-e1bd-4a1b-a974-ec6e6fa8c860', NULL, 1655794873871, NULL);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('0a93a571-e1bd-4a1b-a974-ec6e6fa8c860', NULL, 1655794874645, NULL);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('de2aa99a-81b5-47fd-8565-ef0561f7bb17', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655794877605, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('de2aa99a-81b5-47fd-8565-ef0561f7bb17', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655794879260, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('de2aa99a-81b5-47fd-8565-ef0561f7bb17', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655794880058, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('de2aa99a-81b5-47fd-8565-ef0561f7bb17', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655794880942, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('de2aa99a-81b5-47fd-8565-ef0561f7bb17', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655794881505, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('de2aa99a-81b5-47fd-8565-ef0561f7bb17', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655794885089, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('de2aa99a-81b5-47fd-8565-ef0561f7bb17', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655794886270, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('852a12b9-bbe5-4c93-b55d-5967c09004a9', NULL, 1655794898959, NULL);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('852a12b9-bbe5-4c93-b55d-5967c09004a9', NULL, 1655794902495, NULL);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('852a12b9-bbe5-4c93-b55d-5967c09004a9', NULL, 1655794903125, NULL);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('2d5df47e-b4ec-4ad8-8430-d68ae10e9687', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655794991250, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('de2aa99a-81b5-47fd-8565-ef0561f7bb17', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655794997108, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('2d5df47e-b4ec-4ad8-8430-d68ae10e9687', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655795007321, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('de2aa99a-81b5-47fd-8565-ef0561f7bb17', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655795010985, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('de2aa99a-81b5-47fd-8565-ef0561f7bb17', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655795123378, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('de2aa99a-81b5-47fd-8565-ef0561f7bb17', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655795141732, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('de2aa99a-81b5-47fd-8565-ef0561f7bb17', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655795142134, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('de2aa99a-81b5-47fd-8565-ef0561f7bb17', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655795168001, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('2d5df47e-b4ec-4ad8-8430-d68ae10e9687', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655795524929, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('2d5df47e-b4ec-4ad8-8430-d68ae10e9687', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655795525528, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('2d5df47e-b4ec-4ad8-8430-d68ae10e9687', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655795526225, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('2d5df47e-b4ec-4ad8-8430-d68ae10e9687', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655795526351, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('2d5df47e-b4ec-4ad8-8430-d68ae10e9687', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655795529221, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('de2aa99a-81b5-47fd-8565-ef0561f7bb17', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655795531345, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('de2aa99a-81b5-47fd-8565-ef0561f7bb17', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655795533672, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('de2aa99a-81b5-47fd-8565-ef0561f7bb17', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655795535919, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('de2aa99a-81b5-47fd-8565-ef0561f7bb17', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655795540692, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('2d5df47e-b4ec-4ad8-8430-d68ae10e9687', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655795543397, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('2d5df47e-b4ec-4ad8-8430-d68ae10e9687', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655795545449, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('2d5df47e-b4ec-4ad8-8430-d68ae10e9687', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655795695292, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('2d5df47e-b4ec-4ad8-8430-d68ae10e9687', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655795705656, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('2d5df47e-b4ec-4ad8-8430-d68ae10e9687', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655795707264, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('de2aa99a-81b5-47fd-8565-ef0561f7bb17', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655795723637, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('de2aa99a-81b5-47fd-8565-ef0561f7bb17', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655795726412, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('2d5df47e-b4ec-4ad8-8430-d68ae10e9687', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655795781764, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('de2aa99a-81b5-47fd-8565-ef0561f7bb17', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655795850880, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('de2aa99a-81b5-47fd-8565-ef0561f7bb17', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655795866579, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('de2aa99a-81b5-47fd-8565-ef0561f7bb17', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655795979268, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('de2aa99a-81b5-47fd-8565-ef0561f7bb17', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655796277410, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('de2aa99a-81b5-47fd-8565-ef0561f7bb17', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655795861942, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('de2aa99a-81b5-47fd-8565-ef0561f7bb17', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655796038403, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('de2aa99a-81b5-47fd-8565-ef0561f7bb17', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655796078103, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('de2aa99a-81b5-47fd-8565-ef0561f7bb17', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655796201805, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('de2aa99a-81b5-47fd-8565-ef0561f7bb17', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655796254433, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('2d5df47e-b4ec-4ad8-8430-d68ae10e9687', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655796263400, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('de2aa99a-81b5-47fd-8565-ef0561f7bb17', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655796314294, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('de2aa99a-81b5-47fd-8565-ef0561f7bb17', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655795881920, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('2d5df47e-b4ec-4ad8-8430-d68ae10e9687', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655796038412, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('de2aa99a-81b5-47fd-8565-ef0561f7bb17', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655796040731, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('2d5df47e-b4ec-4ad8-8430-d68ae10e9687', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655796075404, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('de2aa99a-81b5-47fd-8565-ef0561f7bb17', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655796081806, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('2d5df47e-b4ec-4ad8-8430-d68ae10e9687', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655796254420, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('de2aa99a-81b5-47fd-8565-ef0561f7bb17', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655796262713, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('2d5df47e-b4ec-4ad8-8430-d68ae10e9687', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655796301397, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('de2aa99a-81b5-47fd-8565-ef0561f7bb17', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655796075441, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('2d5df47e-b4ec-4ad8-8430-d68ae10e9687', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655796078411, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('2d5df47e-b4ec-4ad8-8430-d68ae10e9687', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655796202392, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('2d5df47e-b4ec-4ad8-8430-d68ae10e9687', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655796277402, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('de2aa99a-81b5-47fd-8565-ef0561f7bb17', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655796301258, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('2d5df47e-b4ec-4ad8-8430-d68ae10e9687', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655796314434, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('de2aa99a-81b5-47fd-8565-ef0561f7bb17', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655796367088, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('2d5df47e-b4ec-4ad8-8430-d68ae10e9687', 'illa/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36', 1655796367398, 13);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('de2aa99a-81b5-47fd-8565-ef0561f7bb17', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655796390898, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('de2aa99a-81b5-47fd-8565-ef0561f7bb17', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655796392802, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('de2aa99a-81b5-47fd-8565-ef0561f7bb17', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655796396198, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('de2aa99a-81b5-47fd-8565-ef0561f7bb17', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655796396870, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('de2aa99a-81b5-47fd-8565-ef0561f7bb17', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655797812486, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('de2aa99a-81b5-47fd-8565-ef0561f7bb17', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655798007667, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('de2aa99a-81b5-47fd-8565-ef0561f7bb17', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655798315387, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('de2aa99a-81b5-47fd-8565-ef0561f7bb17', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655798359903, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('de2aa99a-81b5-47fd-8565-ef0561f7bb17', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655798399588, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('de2aa99a-81b5-47fd-8565-ef0561f7bb17', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655798486897, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('de2aa99a-81b5-47fd-8565-ef0561f7bb17', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655798543399, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('de2aa99a-81b5-47fd-8565-ef0561f7bb17', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655798695511, 15);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('20d1b4d4-1d39-452e-a97c-f869c6c7ef10', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655798886119, 16);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('20d1b4d4-1d39-452e-a97c-f869c6c7ef10', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655798896225, 16);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('20d1b4d4-1d39-452e-a97c-f869c6c7ef10', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655798899363, 16);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('20d1b4d4-1d39-452e-a97c-f869c6c7ef10', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655798906465, 16);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('20d1b4d4-1d39-452e-a97c-f869c6c7ef10', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655798908121, 16);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('20d1b4d4-1d39-452e-a97c-f869c6c7ef10', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655798913107, 16);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('20d1b4d4-1d39-452e-a97c-f869c6c7ef10', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655798915045, 16);
INSERT INTO public.t_history_active_user202206 (use_session_id, user_agent, last_active, user_id) VALUES ('20d1b4d4-1d39-452e-a97c-f869c6c7ef10', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1655798917602, 16);


--
-- TOC entry 3418 (class 0 OID 42287)
-- Dependencies: 209
-- Data for Name: t_old_user; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.t_old_user (user_id, first_name, last_name, patronymic, phone, mail, passport, salt, hash_password, amount, currency) VALUES (2, 'Чудин', 'Бронислав ', 'Романович', '+7 (907) 300-81-95', 'BronislavChudin25@yandex.ru', 1823, 54, 45645645, 14100, 'RUB');
INSERT INTO public.t_old_user (user_id, first_name, last_name, patronymic, phone, mail, passport, salt, hash_password, amount, currency) VALUES (4, 'Ленский ', 'Станимир ', 'Владимирович', '+7 (914) 472-21-68', 'StanimirLenskiy428@mail.ru', 6454, 54, 345345, 2955, 'RUB');
INSERT INTO public.t_old_user (user_id, first_name, last_name, patronymic, phone, mail, passport, salt, hash_password, amount, currency) VALUES (3, 'Конягин ', 'Эрнст ', 'Андреевич', '+7 (931) 031-43-89', 'ErnstKonyagin290@mail.ru', 3453, 23, 6645645, -120, 'RUB');
INSERT INTO public.t_old_user (user_id, first_name, last_name, patronymic, phone, mail, passport, salt, hash_password, amount, currency) VALUES (1, 'Быков', 'Евгений', 'Леонидович', '+7 (971) 458-28-72', 'evgeniy12041980@mail.ru', 1923, 45, 34534534, -4812, 'RUB');
INSERT INTO public.t_old_user (user_id, first_name, last_name, patronymic, phone, mail, passport, salt, hash_password, amount, currency) VALUES (5, 'Сомова ', 'Борислава ', 'Эдуардовна', '+7 (985) 071-70-76', 'BorislavaSomova234@yandex.com', 3434, 65, 23423432, 1000, 'RUB');


--
-- TOC entry 3424 (class 0 OID 91757)
-- Dependencies: 215
-- Data for Name: t_role; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.t_role (id, name) VALUES (1, 'ROLE_USER');


--
-- TOC entry 3433 (class 0 OID 91803)
-- Dependencies: 224
-- Data for Name: t_status_financial_products; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.t_status_financial_products (status_financial_products_id, close_date, open_date, financial_products_financial_products_id, t_user_id) VALUES (8, '2022-06-09 11:15:05.329', '2022-06-09 10:33:40.422', 7, 13);
INSERT INTO public.t_status_financial_products (status_financial_products_id, close_date, open_date, financial_products_financial_products_id, t_user_id) VALUES (7, '2022-06-09 11:15:19.614', NULL, 3, 13);
INSERT INTO public.t_status_financial_products (status_financial_products_id, close_date, open_date, financial_products_financial_products_id, t_user_id) VALUES (9, '2022-06-09 11:23:51.12', '2022-06-09 10:36:06.873', 8, 13);
INSERT INTO public.t_status_financial_products (status_financial_products_id, close_date, open_date, financial_products_financial_products_id, t_user_id) VALUES (10, '2022-06-09 11:23:52.038', '2022-06-09 11:15:21.352', 8, 13);
INSERT INTO public.t_status_financial_products (status_financial_products_id, close_date, open_date, financial_products_financial_products_id, t_user_id) VALUES (11, '2022-06-09 11:23:59.656', '2022-06-09 11:16:50.668', 3, 13);
INSERT INTO public.t_status_financial_products (status_financial_products_id, close_date, open_date, financial_products_financial_products_id, t_user_id) VALUES (12, '2022-06-09 11:25:26.172', '2022-06-09 11:18:17.356', 7, 13);
INSERT INTO public.t_status_financial_products (status_financial_products_id, close_date, open_date, financial_products_financial_products_id, t_user_id) VALUES (13, '2022-06-18 03:00:00', '2022-06-09 11:24:01.597', 6, 13);
INSERT INTO public.t_status_financial_products (status_financial_products_id, close_date, open_date, financial_products_financial_products_id, t_user_id) VALUES (14, '2022-06-25 03:00:00', '2022-06-09 11:26:23.879', 6, 13);
INSERT INTO public.t_status_financial_products (status_financial_products_id, close_date, open_date, financial_products_financial_products_id, t_user_id) VALUES (15, '2022-06-09 14:09:41.677', '2022-06-09 14:08:07.675', 7, 14);
INSERT INTO public.t_status_financial_products (status_financial_products_id, close_date, open_date, financial_products_financial_products_id, t_user_id) VALUES (16, '2022-06-25 03:00:00', '2022-06-09 14:09:44.574', 9, 14);
INSERT INTO public.t_status_financial_products (status_financial_products_id, close_date, open_date, financial_products_financial_products_id, t_user_id) VALUES (17, '2022-06-03 03:00:00', '2022-06-15 10:16:39.121', 4, 15);
INSERT INTO public.t_status_financial_products (status_financial_products_id, close_date, open_date, financial_products_financial_products_id, t_user_id) VALUES (18, '2022-06-03 03:00:00', '2022-06-15 10:16:39.121', 4, 15);
INSERT INTO public.t_status_financial_products (status_financial_products_id, close_date, open_date, financial_products_financial_products_id, t_user_id) VALUES (19, '2022-07-03 03:00:00', '2022-06-15 10:36:08.576', 4, 14);
INSERT INTO public.t_status_financial_products (status_financial_products_id, close_date, open_date, financial_products_financial_products_id, t_user_id) VALUES (20, '2022-07-07 03:00:00', '2022-06-15 10:36:44.567', 6, 15);
INSERT INTO public.t_status_financial_products (status_financial_products_id, close_date, open_date, financial_products_financial_products_id, t_user_id) VALUES (21, '2022-06-26 03:00:00', '2022-06-21 11:08:06.084', 3, 16);


--
-- TOC entry 3426 (class 0 OID 91763)
-- Dependencies: 217
-- Data for Name: t_type_transactions; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.t_type_transactions (type_transactions_id, name) VALUES (1, 'Списание');
INSERT INTO public.t_type_transactions (type_transactions_id, name) VALUES (2, 'пополнение');
INSERT INTO public.t_type_transactions (type_transactions_id, name) VALUES (3, 'перевод');


--
-- TOC entry 3428 (class 0 OID 91770)
-- Dependencies: 219
-- Data for Name: t_user; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.t_user (id, login, password, currency, first_name, last_name, mail, passport, patronymic, phone, amount) VALUES (15, 'cany245mailru246300522', '$2a$10$usbAFHKR7h6FvBMD8f9AT.cnwmJjaZwvpC0CK6r28ZOZ0LC2n3KQ2', 'RUB', 'Александр', 'Ларин', 'cany245@mail.ru', '34534', 'Михайлович', '+7 (607) 300-81-95', 1000000);
INSERT INTO public.t_user (id, login, password, currency, first_name, last_name, mail, passport, patronymic, phone, amount) VALUES (14, 'adsf662401190', '$2a$10$wq40RPWzdbSp3NGQdk2FTOEsOp43gs9nh8q7cCBo71vy3evFjyxVm', 'RUB', 'Данил', 'Скляров', 'adsf', '1323451', 'Скляров', '+7 (907) 300-81-91', 657);
INSERT INTO public.t_user (id, login, password, currency, first_name, last_name, mail, passport, patronymic, phone, amount) VALUES (12, 'cany-1696658031', '$2a$10$2xFLJC024DKF8KNfL2W4s.5yuc6AVTr2Wab9.yZfbSIisudnoPsLa', 'RUB', 'Александр', 'Бородай', 'cany', '2355', 'Михайлович', '+7 (107) 300-81-95', 0);
INSERT INTO public.t_user (id, login, password, currency, first_name, last_name, mail, passport, patronymic, phone, amount) VALUES (13, 'a34dsf662401190', '$2a$10$n65OcNn5.IGODJTYa0Sae.2roBGNGG2/dpyeMsBfym7HyDj/sC7BC', 'RUB', 'Александр', 'Егнатов', '2342', '5235', 'Михайлович', '+7 (407) 300-81-95', 5995);
INSERT INTO public.t_user (id, login, password, currency, first_name, last_name, mail, passport, patronymic, phone, amount) VALUES (16, 'BronislavChudin25yandexru862695246', '$2a$10$4UmUrbwV6zYb6E7409vcKuGKs.nxBP/BbaIvTuMxeWgLwBz.xsV6m', 'RUB', 'Чудин', 'Бронислав', 'BronislavChudin25@yandex.ru', '1823', 'Романович', '+7 (907) 300-81-95', 0);
INSERT INTO public.t_user (id, login, password, currency, first_name, last_name, mail, passport, patronymic, phone, amount) VALUES (17, 'cany245mailru246300522StanimirLenskiy428mailru1393590338', '$2a$10$8m/OOHSY5DidfH87y8y/qOlWvZ/uP3pf2.BC.HtvFgwNswPZzsF4.', 'RUB', 'BronislavChudin25yandexru862695246', 'Станимир', 'cany245mailru246300522StanimirLenskiy428@mail.ru', '6454', 'Владимирович', '+7 (914) 472-21-68', 0);
INSERT INTO public.t_user (id, login, password, currency, first_name, last_name, mail, passport, patronymic, phone, amount) VALUES (18, 'ErnstKonyagin290mailru389446536', '$2a$10$lcBoxb2n8hGG1n3rXl6UAOCHhLUG0CGH9FhB6VvAmpNqFZuxDMtwO', 'RUB', 'Эрнст', 'Конягин', 'ErnstKonyagin290@mail.ru', '345634', 'Андреевич', '+7 (931) 031-43-89', 0);
INSERT INTO public.t_user (id, login, password, currency, first_name, last_name, mail, passport, patronymic, phone, amount) VALUES (19, 'evgeniy12041980mailru-1964229645', '$2a$10$IMaVgnhvMMYIGGnn.LtUXOzuA03fvZd5esYhhXYBz7O2OX71I9OoK', 'RUB', 'Евгений', 'Быков', 'evgeniy12041980@mail.ru', '34534', 'Леонидович', '+7 (971) 458-28-72', 0);
INSERT INTO public.t_user (id, login, password, currency, first_name, last_name, mail, passport, patronymic, phone, amount) VALUES (20, 'BorislavaSomova234yandexcom-1818960182', '$2a$10$JzgJvJgeCCwA6ojej8EqGu4tnf0OQ0264ST9i7b2WhKFovSR0SzRO', 'RUB', 'Борислава', 'Сомова ', 'BorislavaSomova234@yandex.com', '34543', 'Эдуардовна', '+7 (985) 071-70-76', 0);


--
-- TOC entry 3429 (class 0 OID 91778)
-- Dependencies: 220
-- Data for Name: t_user_roles; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.t_user_roles (user_id, roles_id) VALUES (12, 1);
INSERT INTO public.t_user_roles (user_id, roles_id) VALUES (13, 1);
INSERT INTO public.t_user_roles (user_id, roles_id) VALUES (14, 1);
INSERT INTO public.t_user_roles (user_id, roles_id) VALUES (15, 1);
INSERT INTO public.t_user_roles (user_id, roles_id) VALUES (16, 1);
INSERT INTO public.t_user_roles (user_id, roles_id) VALUES (17, 1);
INSERT INTO public.t_user_roles (user_id, roles_id) VALUES (18, 1);
INSERT INTO public.t_user_roles (user_id, roles_id) VALUES (19, 1);
INSERT INTO public.t_user_roles (user_id, roles_id) VALUES (20, 1);


--
-- TOC entry 3447 (class 0 OID 0)
-- Dependencies: 221
-- Name: t_account_transations_account_transactions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.t_account_transations_account_transactions_id_seq', 55, true);


--
-- TOC entry 3448 (class 0 OID 0)
-- Dependencies: 213
-- Name: t_financial_products_financial_products_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.t_financial_products_financial_products_id_seq', 1, false);


--
-- TOC entry 3449 (class 0 OID 0)
-- Dependencies: 223
-- Name: t_status_financial_products_status_financial_products_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.t_status_financial_products_status_financial_products_id_seq', 21, true);


--
-- TOC entry 3450 (class 0 OID 0)
-- Dependencies: 216
-- Name: t_type_transactions_type_transactions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.t_type_transactions_type_transactions_id_seq', 1, false);


--
-- TOC entry 3451 (class 0 OID 0)
-- Dependencies: 218
-- Name: t_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.t_user_id_seq', 20, true);


--
-- TOC entry 3452 (class 0 OID 0)
-- Dependencies: 210
-- Name: user_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.user_user_id_seq', 5, true);


--
-- TOC entry 3250 (class 2606 OID 91630)
-- Name: spring_session_attributes spring_session_attributes_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.spring_session_attributes
    ADD CONSTRAINT spring_session_attributes_pk PRIMARY KEY (session_primary_id, attribute_name);


--
-- TOC entry 3248 (class 2606 OID 91620)
-- Name: spring_session spring_session_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.spring_session
    ADD CONSTRAINT spring_session_pk PRIMARY KEY (primary_id);


--
-- TOC entry 3263 (class 2606 OID 91801)
-- Name: t_account_transations t_account_transations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.t_account_transations
    ADD CONSTRAINT t_account_transations_pkey PRIMARY KEY (account_transactions_id);


--
-- TOC entry 3252 (class 2606 OID 91749)
-- Name: t_financial_products t_financial_products_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.t_financial_products
    ADD CONSTRAINT t_financial_products_pkey PRIMARY KEY (financial_products_id);


--
-- TOC entry 3254 (class 2606 OID 91761)
-- Name: t_role t_role_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.t_role
    ADD CONSTRAINT t_role_pkey PRIMARY KEY (id);


--
-- TOC entry 3265 (class 2606 OID 91810)
-- Name: t_status_financial_products t_status_financial_products_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.t_status_financial_products
    ADD CONSTRAINT t_status_financial_products_pkey PRIMARY KEY (status_financial_products_id);


--
-- TOC entry 3256 (class 2606 OID 91768)
-- Name: t_type_transactions t_type_transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.t_type_transactions
    ADD CONSTRAINT t_type_transactions_pkey PRIMARY KEY (type_transactions_id);


--
-- TOC entry 3259 (class 2606 OID 91777)
-- Name: t_user t_user_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.t_user
    ADD CONSTRAINT t_user_pkey PRIMARY KEY (id);


--
-- TOC entry 3261 (class 2606 OID 91782)
-- Name: t_user_roles t_user_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.t_user_roles
    ADD CONSTRAINT t_user_roles_pkey PRIMARY KEY (user_id, roles_id);


--
-- TOC entry 3243 (class 2606 OID 42293)
-- Name: t_old_user user_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.t_old_user
    ADD CONSTRAINT user_pk PRIMARY KEY (user_id);


--
-- TOC entry 3244 (class 1259 OID 91621)
-- Name: spring_session_ix1; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX spring_session_ix1 ON public.spring_session USING btree (session_id);


--
-- TOC entry 3245 (class 1259 OID 91622)
-- Name: spring_session_ix2; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX spring_session_ix2 ON public.spring_session USING btree (expiry_time);


--
-- TOC entry 3246 (class 1259 OID 91623)
-- Name: spring_session_ix3; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX spring_session_ix3 ON public.spring_session USING btree (principal_name);


--
-- TOC entry 3267 (class 1259 OID 124394)
-- Name: t_history_active_user202203_last_active_user_agent_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX t_history_active_user202203_last_active_user_agent_idx ON public.t_history_active_user202203 USING btree (last_active, user_agent);


--
-- TOC entry 3266 (class 1259 OID 124387)
-- Name: t_history_active_user202206_last_active_user_agent_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX t_history_active_user202206_last_active_user_agent_idx ON public.t_history_active_user202206 USING btree (last_active, user_agent);


--
-- TOC entry 3257 (class 1259 OID 99841)
-- Name: t_user_login_uindex; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX t_user_login_uindex ON public.t_user USING btree (login);


--
-- TOC entry 3416 (class 2618 OID 124417)
-- Name: summary_information_about_the_client _RETURN; Type: RULE; Schema: public; Owner: -
--

CREATE OR REPLACE VIEW public.summary_information_about_the_client AS
 SELECT (((((t_user.first_name)::text || ' '::text) || (t_user.last_name)::text) || ' '::text) || (t_user.patronymic)::text) AS fcs,
    ((t_user.amount || ' '::text) || (t_user.currency)::text) AS amount,
    max(us.last_active) AS lastactivitydate
   FROM (public.t_user
     JOIN public.history_active_user_simple us ON ((t_user.id = us.user_id)))
  GROUP BY t_user.id;


--
-- TOC entry 3276 (class 2620 OID 108011)
-- Name: t_account_transations make_operation_after; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER make_operation_after AFTER INSERT ON public.t_account_transations FOR EACH ROW EXECUTE FUNCTION public.make_operation();


--
-- TOC entry 3275 (class 2620 OID 99818)
-- Name: spring_session save_history_active_after; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER save_history_active_after AFTER UPDATE ON public.spring_session FOR EACH ROW EXECUTE FUNCTION public.save_history_active();


--
-- TOC entry 3272 (class 2606 OID 99808)
-- Name: t_account_transations fk9aric8jf1um0f01tsxtyu7pot; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.t_account_transations
    ADD CONSTRAINT fk9aric8jf1um0f01tsxtyu7pot FOREIGN KEY (t_user_id) REFERENCES public.t_user(id);


--
-- TOC entry 3273 (class 2606 OID 91816)
-- Name: t_status_financial_products fkiv6v43iaucnjnvv2hkp5xawrr; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.t_status_financial_products
    ADD CONSTRAINT fkiv6v43iaucnjnvv2hkp5xawrr FOREIGN KEY (financial_products_financial_products_id) REFERENCES public.t_financial_products(financial_products_id);


--
-- TOC entry 3269 (class 2606 OID 91783)
-- Name: t_user_roles fkj47yp3hhtsoajht9793tbdrp4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.t_user_roles
    ADD CONSTRAINT fkj47yp3hhtsoajht9793tbdrp4 FOREIGN KEY (roles_id) REFERENCES public.t_role(id);


--
-- TOC entry 3271 (class 2606 OID 91811)
-- Name: t_account_transations fkkivy2vbvxwlkghkkiccge9g1q; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.t_account_transations
    ADD CONSTRAINT fkkivy2vbvxwlkghkkiccge9g1q FOREIGN KEY (type_transactions_type_transactions_id) REFERENCES public.t_type_transactions(type_transactions_id);


--
-- TOC entry 3274 (class 2606 OID 99813)
-- Name: t_status_financial_products fko19l3kh27p9dfd7qsvebdp9gr; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.t_status_financial_products
    ADD CONSTRAINT fko19l3kh27p9dfd7qsvebdp9gr FOREIGN KEY (t_user_id) REFERENCES public.t_user(id);


--
-- TOC entry 3270 (class 2606 OID 91788)
-- Name: t_user_roles fkpqntgokae5e703qb206xvfdk3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.t_user_roles
    ADD CONSTRAINT fkpqntgokae5e703qb206xvfdk3 FOREIGN KEY (user_id) REFERENCES public.t_user(id);


--
-- TOC entry 3268 (class 2606 OID 91631)
-- Name: spring_session_attributes spring_session_attributes_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.spring_session_attributes
    ADD CONSTRAINT spring_session_attributes_fk FOREIGN KEY (session_primary_id) REFERENCES public.spring_session(primary_id) ON DELETE CASCADE;


-- Completed on 2022-06-21 11:27:40

--
-- PostgreSQL database dump complete
--

