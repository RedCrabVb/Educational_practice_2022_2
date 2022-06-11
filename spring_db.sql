--
-- PostgreSQL database dump
--

-- Dumped from database version 14.2 (Debian 14.2-1.pgdg110+1)
-- Dumped by pg_dump version 14.1

-- Started on 2022-06-11 13:57:35

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
-- TOC entry 239 (class 1255 OID 42391)
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
-- TOC entry 230 (class 1255 OID 42371)
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
-- TOC entry 240 (class 1255 OID 42367)
-- Name: save_history_active(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.save_history_active() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF new.last_access_time != old.last_access_time THEN
        insert into t_history_active_user (last_active, use_session_id, user_agent, user_id)
         values (NEW.last_access_time, NEW.primary_id,
                 substr(encode((select attribute_bytes from spring_session_attributes
                    where session_primary_id = NEW.primary_id and attribute_name = 'user_agent'), 'escape'), 23),
                 (select id from t_user where login = old.principal_name));
    END IF;
    RETURN NEW;
END;
$$;


SET default_tablespace = '';

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
-- TOC entry 224 (class 1259 OID 91794)
-- Name: t_account_transations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.t_account_transations (
    account_transactions_id bigint NOT NULL,
    transfer_account character varying(255),
    amount integer NOT NULL,
    currency character varying(255),
    date timestamp without time zone,
    t_user bytea,
    type_transactions_type_transactions_id bigint,
    t_user_id bigint
);


--
-- TOC entry 223 (class 1259 OID 91793)
-- Name: t_account_transations_account_transactions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.t_account_transations_account_transactions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3421 (class 0 OID 0)
-- Dependencies: 223
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
-- TOC entry 3422 (class 0 OID 0)
-- Dependencies: 213
-- Name: t_financial_products_financial_products_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.t_financial_products_financial_products_id_seq OWNED BY public.t_financial_products.financial_products_id;


--
-- TOC entry 216 (class 1259 OID 91751)
-- Name: t_history_active_user; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.t_history_active_user (
    history_active_user_id integer NOT NULL,
    use_session_id character(36) NOT NULL,
    user_agent character varying(255),
    last_active bigint,
    user_id bigint
);


--
-- TOC entry 215 (class 1259 OID 91750)
-- Name: t_history_active_user_history_active_user_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.t_history_active_user_history_active_user_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3423 (class 0 OID 0)
-- Dependencies: 215
-- Name: t_history_active_user_history_active_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.t_history_active_user_history_active_user_id_seq OWNED BY public.t_history_active_user.history_active_user_id;


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
-- TOC entry 217 (class 1259 OID 91757)
-- Name: t_role; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.t_role (
    id bigint NOT NULL,
    name character varying(255)
);


--
-- TOC entry 226 (class 1259 OID 91803)
-- Name: t_status_financial_products; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.t_status_financial_products (
    status_financial_products_id bigint NOT NULL,
    close_date timestamp without time zone,
    open_date timestamp without time zone,
    t_user bytea,
    financial_products_financial_products_id bigint,
    t_user_id bigint
);


--
-- TOC entry 225 (class 1259 OID 91802)
-- Name: t_status_financial_products_status_financial_products_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.t_status_financial_products_status_financial_products_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3424 (class 0 OID 0)
-- Dependencies: 225
-- Name: t_status_financial_products_status_financial_products_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.t_status_financial_products_status_financial_products_id_seq OWNED BY public.t_status_financial_products.status_financial_products_id;


--
-- TOC entry 219 (class 1259 OID 91763)
-- Name: t_type_transactions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.t_type_transactions (
    type_transactions_id bigint NOT NULL,
    name character varying(255)
);


--
-- TOC entry 218 (class 1259 OID 91762)
-- Name: t_type_transactions_type_transactions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.t_type_transactions_type_transactions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3425 (class 0 OID 0)
-- Dependencies: 218
-- Name: t_type_transactions_type_transactions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.t_type_transactions_type_transactions_id_seq OWNED BY public.t_type_transactions.type_transactions_id;


--
-- TOC entry 221 (class 1259 OID 91770)
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
-- TOC entry 220 (class 1259 OID 91769)
-- Name: t_user_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.t_user_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 3426 (class 0 OID 0)
-- Dependencies: 220
-- Name: t_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.t_user_id_seq OWNED BY public.t_user.id;


--
-- TOC entry 222 (class 1259 OID 91778)
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
-- TOC entry 3427 (class 0 OID 0)
-- Dependencies: 210
-- Name: user_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_user_id_seq OWNED BY public.t_old_user.user_id;


--
-- TOC entry 3223 (class 2604 OID 91797)
-- Name: t_account_transations account_transactions_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.t_account_transations ALTER COLUMN account_transactions_id SET DEFAULT nextval('public.t_account_transations_account_transactions_id_seq'::regclass);


--
-- TOC entry 3219 (class 2604 OID 91745)
-- Name: t_financial_products financial_products_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.t_financial_products ALTER COLUMN financial_products_id SET DEFAULT nextval('public.t_financial_products_financial_products_id_seq'::regclass);


--
-- TOC entry 3220 (class 2604 OID 91754)
-- Name: t_history_active_user history_active_user_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.t_history_active_user ALTER COLUMN history_active_user_id SET DEFAULT nextval('public.t_history_active_user_history_active_user_id_seq'::regclass);


--
-- TOC entry 3218 (class 2604 OID 42321)
-- Name: t_old_user user_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.t_old_user ALTER COLUMN user_id SET DEFAULT nextval('public.user_user_id_seq'::regclass);


--
-- TOC entry 3224 (class 2604 OID 91806)
-- Name: t_status_financial_products status_financial_products_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.t_status_financial_products ALTER COLUMN status_financial_products_id SET DEFAULT nextval('public.t_status_financial_products_status_financial_products_id_seq'::regclass);


--
-- TOC entry 3221 (class 2604 OID 91766)
-- Name: t_type_transactions type_transactions_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.t_type_transactions ALTER COLUMN type_transactions_id SET DEFAULT nextval('public.t_type_transactions_type_transactions_id_seq'::regclass);


--
-- TOC entry 3222 (class 2604 OID 91773)
-- Name: t_user id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.t_user ALTER COLUMN id SET DEFAULT nextval('public.t_user_id_seq'::regclass);


--
-- TOC entry 3400 (class 0 OID 91616)
-- Dependencies: 211
-- Data for Name: spring_session; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.spring_session (primary_id, session_id, creation_time, last_access_time, max_inactive_interval, expiry_time, principal_name) VALUES ('365b0a69-35c3-4721-9162-90fdbeab2dcf', 'e3cbbfa5-6d24-4a6a-84dc-4fc250a0d8a6', 1654940366465, 1654944872191, 1800, 1654946672191, '2342644593376');


--
-- TOC entry 3401 (class 0 OID 91624)
-- Dependencies: 212
-- Data for Name: spring_session_attributes; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.spring_session_attributes (session_primary_id, attribute_name, attribute_bytes) VALUES ('365b0a69-35c3-4721-9162-90fdbeab2dcf', 'SPRING_SECURITY_CONTEXT', '\xaced00057372003d6f72672e737072696e676672616d65776f726b2e73656375726974792e636f72652e636f6e746578742e5365637572697479436f6e74657874496d706c00000000000002580200014c000e61757468656e7469636174696f6e7400324c6f72672f737072696e676672616d65776f726b2f73656375726974792f636f72652f41757468656e7469636174696f6e3b78707372004f6f72672e737072696e676672616d65776f726b2e73656375726974792e61757468656e7469636174696f6e2e557365726e616d6550617373776f726441757468656e7469636174696f6e546f6b656e00000000000002580200024c000b63726564656e7469616c737400124c6a6176612f6c616e672f4f626a6563743b4c00097072696e636970616c71007e0004787200476f72672e737072696e676672616d65776f726b2e73656375726974792e61757468656e7469636174696f6e2e416273747261637441757468656e7469636174696f6e546f6b656ed3aa287e6e47640e0200035a000d61757468656e746963617465644c000b617574686f7269746965737400164c6a6176612f7574696c2f436f6c6c656374696f6e3b4c000764657461696c7371007e0004787001737200266a6176612e7574696c2e436f6c6c656374696f6e7324556e6d6f6469666961626c654c697374fc0f2531b5ec8e100200014c00046c6973747400104c6a6176612f7574696c2f4c6973743b7872002c6a6176612e7574696c2e436f6c6c656374696f6e7324556e6d6f6469666961626c65436f6c6c656374696f6e19420080cb5ef71e0200014c00016371007e00067870737200136a6176612e7574696c2e41727261794c6973747881d21d99c7619d03000149000473697a657870000000017704000000017372001a72752e6e656f666c65782e6170702e646f6d61696e2e526f6c65c504813114c93ede0200034c000269647400104c6a6176612f6c616e672f4c6f6e673b4c00046e616d657400124c6a6176612f6c616e672f537472696e673b4c0005757365727374000f4c6a6176612f7574696c2f5365743b78707372000e6a6176612e6c616e672e4c6f6e673b8be490cc8f23df0200014a000576616c7565787200106a6176612e6c616e672e4e756d62657286ac951d0b94e08b02000078700000000000000001740009524f4c455f55534552707871007e000d737200486f72672e737072696e676672616d65776f726b2e73656375726974792e7765622e61757468656e7469636174696f6e2e57656241757468656e7469636174696f6e44657461696c7300000000000002580200024c000d72656d6f74654164647265737371007e00104c000973657373696f6e496471007e0010787074000f303a303a303a303a303a303a303a3174002434613731353761662d633834342d346539392d613837362d303239643761336236613562707372001a72752e6e656f666c65782e6170702e646f6d61696e2e557365724d70fd8572b5be8102000c490006616d6f756e744c000863757272656e637971007e00104c000966697273744e616d6571007e00104c0002696471007e000f4c00086c6173744e616d6571007e00104c00056c6f67696e71007e00104c00046d61696c71007e00104c000870617373706f727471007e00104c000870617373776f726471007e00104c000a706174726f6e796d696371007e00104c000570686f6e6571007e00104c0005726f6c657371007e00117870000026e9740003525542740012d090d0bbd0b5d0bad181d0b0d0bdd0b4d1807371007e0013000000000000000d74000ed091d0bed180d0bed0b4d0b0d0b974000d32333432363434353933333736740004323334327074003c243261243130246e36354f634e6e352e49474f444a545961305361652e32726f42474e4747322f647079654d734266796d374879446a2f7343374243740014d09cd0b8d185d0b0d0b9d0bbd0bed0b2d0b8d187707372002f6f72672e68696265726e6174652e636f6c6c656374696f6e2e696e7465726e616c2e50657273697374656e745365748b47ef79d4c9917d0200014c000373657471007e00117872003e6f72672e68696265726e6174652e636f6c6c656374696f6e2e696e7465726e616c2e416273747261637450657273697374656e74436f6c6c656374696f6e5718b75d8aba735402000b5a001b616c6c6f774c6f61644f7574736964655472616e73616374696f6e49000a63616368656453697a655a000564697274795a000e656c656d656e7452656d6f7665645a000b696e697469616c697a65645a000d697354656d7053657373696f6e4c00036b65797400164c6a6176612f696f2f53657269616c697a61626c653b4c00056f776e657271007e00044c0004726f6c6571007e00104c001273657373696f6e466163746f72795575696471007e00104c000e73746f726564536e617073686f7471007e0027787000ffffffff0000010071007e001f71007e001c74002072752e6e656f666c65782e6170702e646f6d61696e2e557365722e726f6c657370737200116a6176612e7574696c2e486173684d61700507dac1c31660d103000246000a6c6f6164466163746f724900097468726573686f6c6478703f400000000000017708000000020000000171007e001271007e001278737200116a6176612e7574696c2e48617368536574ba44859596b8b7340300007870770c000000103f4000000000000171007e001278');
INSERT INTO public.spring_session_attributes (session_primary_id, attribute_name, attribute_bytes) VALUES ('365b0a69-35c3-4721-9162-90fdbeab2dcf', 'user_agent', '\xaced00057400944d6f7a696c6c612f352e30202857696e646f7773204e542031302e303b2057696e36343b2078363429204170706c655765624b69742f3533372e333620284b48544d4c2c206c696b65204765636b6f29204368726f6d652f3130302e302e343839362e31363020596142726f777365722f32322e352e322e36313520596f777365722f322e35205361666172692f3533372e3336');


--
-- TOC entry 3413 (class 0 OID 91794)
-- Dependencies: 224
-- Data for Name: t_account_transations; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.t_account_transations (account_transactions_id, transfer_account, amount, currency, date, t_user, type_transactions_type_transactions_id, t_user_id) VALUES (1, NULL, 0, 'RUB', '2022-06-09 13:11:00.787', NULL, 2, 14);
INSERT INTO public.t_account_transations (account_transactions_id, transfer_account, amount, currency, date, t_user, type_transactions_type_transactions_id, t_user_id) VALUES (2, NULL, 9, 'RUB', '2022-06-09 13:11:00.787', NULL, 1, 14);
INSERT INTO public.t_account_transations (account_transactions_id, transfer_account, amount, currency, date, t_user, type_transactions_type_transactions_id, t_user_id) VALUES (3, NULL, 0, 'RUB', '2022-06-09 13:12:21.91', NULL, 2, 14);
INSERT INTO public.t_account_transations (account_transactions_id, transfer_account, amount, currency, date, t_user, type_transactions_type_transactions_id, t_user_id) VALUES (4, NULL, 999, 'RUB', '2022-06-09 13:12:21.91', NULL, 1, 14);
INSERT INTO public.t_account_transations (account_transactions_id, transfer_account, amount, currency, date, t_user, type_transactions_type_transactions_id, t_user_id) VALUES (5, NULL, 10, 'RUB', '2022-06-09 14:01:26.279', NULL, 2, 13);
INSERT INTO public.t_account_transations (account_transactions_id, transfer_account, amount, currency, date, t_user, type_transactions_type_transactions_id, t_user_id) VALUES (6, NULL, 10, 'RUB', '2022-06-09 14:01:26.279', NULL, 1, 14);
INSERT INTO public.t_account_transations (account_transactions_id, transfer_account, amount, currency, date, t_user, type_transactions_type_transactions_id, t_user_id) VALUES (7, NULL, 10000, 'RUB', '2022-06-09 14:11:11.73', NULL, 2, 13);
INSERT INTO public.t_account_transations (account_transactions_id, transfer_account, amount, currency, date, t_user, type_transactions_type_transactions_id, t_user_id) VALUES (8, NULL, 10000, 'RUB', '2022-06-09 14:11:11.73', NULL, 1, 14);
INSERT INTO public.t_account_transations (account_transactions_id, transfer_account, amount, currency, date, t_user, type_transactions_type_transactions_id, t_user_id) VALUES (9, NULL, 49, 'RUB', '2022-06-09 14:12:53.748', NULL, 2, 14);
INSERT INTO public.t_account_transations (account_transactions_id, transfer_account, amount, currency, date, t_user, type_transactions_type_transactions_id, t_user_id) VALUES (10, NULL, 49, 'RUB', '2022-06-09 14:12:53.748', NULL, 1, 13);


--
-- TOC entry 3403 (class 0 OID 91742)
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
-- TOC entry 3405 (class 0 OID 91751)
-- Dependencies: 216
-- Data for Name: t_history_active_user; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (1, 'ffc5389a-4d3b-4b3c-aa1b-7c5833d7637c', NULL, 1654930671308, NULL);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (2, 'ffc5389a-4d3b-4b3c-aa1b-7c5833d7637c', NULL, 1654930676212, NULL);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (3, 'ffc5389a-4d3b-4b3c-aa1b-7c5833d7637c', NULL, 1654930676255, NULL);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (4, 'ffc5389a-4d3b-4b3c-aa1b-7c5833d7637c', NULL, 1654930678027, NULL);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (12, 'ffc5389a-4d3b-4b3c-aa1b-7c5833d7637c', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654933337467, NULL);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (13, 'ffc5389a-4d3b-4b3c-aa1b-7c5833d7637c', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654933351753, NULL);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (24, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 345, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (7, 'ffc5389a-4d3b-4b3c-aa1b-7c5833d7637c', '0', 1654930725686, NULL);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (8, 'ffc5389a-4d3b-4b3c-aa1b-7c5833d7637c', '0', 1654930808555, NULL);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (6, 'ffc5389a-4d3b-4b3c-aa1b-7c5833d7637c', '0', 1000, NULL);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (10, 'ffc5389a-4d3b-4b3c-aa1b-7c5833d7637c', '0', 1654932358577, NULL);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (15, 'ffc5389a-4d3b-4b3c-aa1b-7c5833d7637c', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654933516109, NULL);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (16, 'ffc5389a-4d3b-4b3c-aa1b-7c5833d7637c', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654933891635, NULL);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (17, 'ffc5389a-4d3b-4b3c-aa1b-7c5833d7637c', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654933924540, NULL);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (18, '365b0a69-35c3-4721-9162-90fdbeab2dcf', NULL, 1654940366511, NULL);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (19, '365b0a69-35c3-4721-9162-90fdbeab2dcf', NULL, 1654940369401, NULL);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (20, '365b0a69-35c3-4721-9162-90fdbeab2dcf', NULL, 1654940369677, NULL);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (21, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654940662354, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (22, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654940666904, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (23, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654940902274, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (25, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654940982473, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (26, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654941445129, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (28, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654941445434, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (29, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654941445129, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (30, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654941445623, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (31, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654941659496, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (32, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654941659541, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (33, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654941659496, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (34, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654941659639, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (35, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654941661059, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (40, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654941665474, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (41, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654941665518, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (42, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654941665526, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (46, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654941762855, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (47, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654941762868, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (11, 'ffc5389a-4d3b-4b3c-aa1b-7c5833d7637c', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1254933333182, NULL);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (9, 'ffc5389a-4d3b-4b3c-aa1b-7c5833d7637c', '0', 1254932350823, NULL);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (5, 'ffc5389a-4d3b-4b3c-aa1b-7c5833d7637c', NULL, 1354930678518, NULL);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (14, 'ffc5389a-4d3b-4b3c-aa1b-7c5833d7637c', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 345, NULL);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (36, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654941661125, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (38, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654941663368, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (43, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654941665533, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (44, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654941762808, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (48, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654941762878, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (37, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654941663324, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (39, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654941663386, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (45, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654941762815, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (49, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654942348421, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (50, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654942348644, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (51, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654942348421, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (52, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654942348712, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (53, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654942348421, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (54, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654942348899, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (27, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 346, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (55, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654942380289, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (56, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654943045218, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (57, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654942774142, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (58, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654943045216, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (59, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654942774130, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (60, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654943045214, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (61, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654943045229, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (62, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654942380289, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (63, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654942774134, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (64, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654943045215, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (65, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654943425504, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (66, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654943425798, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (67, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654943425835, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (68, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654943425504, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (69, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654943426068, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (70, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654943464387, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (71, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654943464388, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (72, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654943464387, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (73, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654943464426, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (74, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654943464434, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (75, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654943464454, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (76, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654943608399, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (77, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654943608443, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (78, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654943608450, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (80, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654943613622, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (82, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654943613669, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (94, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654943733637, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (101, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654943834240, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (79, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654943608464, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (81, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654943613658, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (85, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654943658424, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (88, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654943730387, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (90, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654943730431, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (100, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654943834233, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (83, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654943613677, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (84, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654943658390, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (87, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654943658439, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (91, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654943730441, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (93, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654943733593, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (96, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654943733669, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (98, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654943834183, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (86, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654943658435, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (89, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654943730422, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (92, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654943733586, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (95, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654943733654, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (97, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654943834178, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (99, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654943834224, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (102, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654943887380, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (103, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654943887381, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (104, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654943887384, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (105, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654943887446, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (106, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654943887457, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (107, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654943887463, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (108, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654943889945, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (109, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654943889948, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (110, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654943889981, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (111, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654943889995, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (112, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654943890007, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (113, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654944030387, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (114, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654944030391, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (115, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654944030393, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (116, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654944030425, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (117, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654944030431, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (118, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654944030443, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (119, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654944216403, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (120, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654944216409, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (121, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654944216410, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (122, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654944216468, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (123, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654944216461, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (124, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654944216478, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (125, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654944219522, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (126, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654944219566, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (127, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654944219582, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (128, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654944219585, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (129, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654944280921, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (130, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654944280952, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (133, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654944287900, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (137, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654944288018, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (139, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654944308469, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (145, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654944495311, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (152, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654944695652, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (154, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654944760336, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (158, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654944760401, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (131, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654944280963, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (140, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654944308500, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (146, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654944495327, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (150, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654944695638, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (156, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654944760387, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (132, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654944280973, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (135, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654944287992, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (142, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654944308518, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (149, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654944695608, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (155, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654944760338, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (159, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654944872096, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (162, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654944872174, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (134, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654944287899, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (136, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654944288003, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (138, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654944308465, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (141, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654944308509, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (143, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654944390985, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (144, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654944495277, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (147, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654944495331, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (148, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654944695606, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (151, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654944695642, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (153, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654944760334, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (157, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654944760392, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (160, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654944872103, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (161, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654944872158, 13);
INSERT INTO public.t_history_active_user (history_active_user_id, use_session_id, user_agent, last_active, user_id) VALUES (163, '365b0a69-35c3-4721-9162-90fdbeab2dcf', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.4896.160 YaBrowser/22.5.2.615 Yowser/2.5 Safari/537.36', 1654944872191, 13);


--
-- TOC entry 3398 (class 0 OID 42287)
-- Dependencies: 209
-- Data for Name: t_old_user; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.t_old_user (user_id, first_name, last_name, patronymic, phone, mail, passport, salt, hash_password, amount, currency) VALUES (2, 'Чудин', 'Бронислав ', 'Романович', '+7 (907) 300-81-95', 'BronislavChudin25@yandex.ru', 1823, 54, 45645645, 14100, 'RUB');
INSERT INTO public.t_old_user (user_id, first_name, last_name, patronymic, phone, mail, passport, salt, hash_password, amount, currency) VALUES (4, 'Ленский ', 'Станимир ', 'Владимирович', '+7 (914) 472-21-68', 'StanimirLenskiy428@mail.ru', 6454, 54, 345345, 2955, 'RUB');
INSERT INTO public.t_old_user (user_id, first_name, last_name, patronymic, phone, mail, passport, salt, hash_password, amount, currency) VALUES (3, 'Конягин ', 'Эрнст ', 'Андреевич', '+7 (931) 031-43-89', 'ErnstKonyagin290@mail.ru', 3453, 23, 6645645, -120, 'RUB');
INSERT INTO public.t_old_user (user_id, first_name, last_name, patronymic, phone, mail, passport, salt, hash_password, amount, currency) VALUES (1, 'Быков', 'Евгений', 'Леонидович', '+7 (971) 458-28-72', 'evgeniy12041980@mail.ru', 1923, 45, 34534534, -4812, 'RUB');
INSERT INTO public.t_old_user (user_id, first_name, last_name, patronymic, phone, mail, passport, salt, hash_password, amount, currency) VALUES (5, 'Сомова ', 'Борислава ', 'Эдуардовна', '+7 (985) 071-70-76', 'BorislavaSomova234@yandex.com', 3434, 65, 23423432, 1000, 'RUB');


--
-- TOC entry 3406 (class 0 OID 91757)
-- Dependencies: 217
-- Data for Name: t_role; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.t_role (id, name) VALUES (1, 'ROLE_USER');


--
-- TOC entry 3415 (class 0 OID 91803)
-- Dependencies: 226
-- Data for Name: t_status_financial_products; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.t_status_financial_products (status_financial_products_id, close_date, open_date, t_user, financial_products_financial_products_id, t_user_id) VALUES (8, '2022-06-09 11:15:05.329', '2022-06-09 10:33:40.422', NULL, 7, 13);
INSERT INTO public.t_status_financial_products (status_financial_products_id, close_date, open_date, t_user, financial_products_financial_products_id, t_user_id) VALUES (7, '2022-06-09 11:15:19.614', NULL, NULL, 3, 13);
INSERT INTO public.t_status_financial_products (status_financial_products_id, close_date, open_date, t_user, financial_products_financial_products_id, t_user_id) VALUES (9, '2022-06-09 11:23:51.12', '2022-06-09 10:36:06.873', NULL, 8, 13);
INSERT INTO public.t_status_financial_products (status_financial_products_id, close_date, open_date, t_user, financial_products_financial_products_id, t_user_id) VALUES (10, '2022-06-09 11:23:52.038', '2022-06-09 11:15:21.352', NULL, 8, 13);
INSERT INTO public.t_status_financial_products (status_financial_products_id, close_date, open_date, t_user, financial_products_financial_products_id, t_user_id) VALUES (11, '2022-06-09 11:23:59.656', '2022-06-09 11:16:50.668', NULL, 3, 13);
INSERT INTO public.t_status_financial_products (status_financial_products_id, close_date, open_date, t_user, financial_products_financial_products_id, t_user_id) VALUES (12, '2022-06-09 11:25:26.172', '2022-06-09 11:18:17.356', NULL, 7, 13);
INSERT INTO public.t_status_financial_products (status_financial_products_id, close_date, open_date, t_user, financial_products_financial_products_id, t_user_id) VALUES (13, '2022-06-18 03:00:00', '2022-06-09 11:24:01.597', NULL, 6, 13);
INSERT INTO public.t_status_financial_products (status_financial_products_id, close_date, open_date, t_user, financial_products_financial_products_id, t_user_id) VALUES (14, '2022-06-25 03:00:00', '2022-06-09 11:26:23.879', NULL, 6, 13);
INSERT INTO public.t_status_financial_products (status_financial_products_id, close_date, open_date, t_user, financial_products_financial_products_id, t_user_id) VALUES (15, '2022-06-09 14:09:41.677', '2022-06-09 14:08:07.675', NULL, 7, 14);
INSERT INTO public.t_status_financial_products (status_financial_products_id, close_date, open_date, t_user, financial_products_financial_products_id, t_user_id) VALUES (16, '2022-06-25 03:00:00', '2022-06-09 14:09:44.574', NULL, 9, 14);


--
-- TOC entry 3408 (class 0 OID 91763)
-- Dependencies: 219
-- Data for Name: t_type_transactions; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.t_type_transactions (type_transactions_id, name) VALUES (1, 'Списание');
INSERT INTO public.t_type_transactions (type_transactions_id, name) VALUES (2, 'пополнение');
INSERT INTO public.t_type_transactions (type_transactions_id, name) VALUES (3, 'перевод');


--
-- TOC entry 3410 (class 0 OID 91770)
-- Dependencies: 221
-- Data for Name: t_user; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.t_user (id, login, password, currency, first_name, last_name, mail, passport, patronymic, phone, amount) VALUES (12, 'cany-1696658031', '$2a$10$2xFLJC024DKF8KNfL2W4s.5yuc6AVTr2Wab9.yZfbSIisudnoPsLa', 'RUB', 'Александр', 'Бородай', 'cany', NULL, 'Михайлович', NULL, 0);
INSERT INTO public.t_user (id, login, password, currency, first_name, last_name, mail, passport, patronymic, phone, amount) VALUES (13, '2342644593376', '$2a$10$n65OcNn5.IGODJTYa0Sae.2roBGNGG2/dpyeMsBfym7HyDj/sC7BC', 'RUB', 'Александр', 'Бородай', '2342', NULL, 'Михайлович', NULL, 9961);
INSERT INTO public.t_user (id, login, password, currency, first_name, last_name, mail, passport, patronymic, phone, amount) VALUES (14, 'adsf662401190', '$2a$10$wq40RPWzdbSp3NGQdk2FTOEsOp43gs9nh8q7cCBo71vy3evFjyxVm', 'RUB', 'Данил', 'Скляров', 'adsf', NULL, 'Скляров', NULL, -9961);


--
-- TOC entry 3411 (class 0 OID 91778)
-- Dependencies: 222
-- Data for Name: t_user_roles; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.t_user_roles (user_id, roles_id) VALUES (12, 1);
INSERT INTO public.t_user_roles (user_id, roles_id) VALUES (13, 1);
INSERT INTO public.t_user_roles (user_id, roles_id) VALUES (14, 1);


--
-- TOC entry 3428 (class 0 OID 0)
-- Dependencies: 223
-- Name: t_account_transations_account_transactions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.t_account_transations_account_transactions_id_seq', 10, true);


--
-- TOC entry 3429 (class 0 OID 0)
-- Dependencies: 213
-- Name: t_financial_products_financial_products_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.t_financial_products_financial_products_id_seq', 1, false);


--
-- TOC entry 3430 (class 0 OID 0)
-- Dependencies: 215
-- Name: t_history_active_user_history_active_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.t_history_active_user_history_active_user_id_seq', 163, true);


--
-- TOC entry 3431 (class 0 OID 0)
-- Dependencies: 225
-- Name: t_status_financial_products_status_financial_products_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.t_status_financial_products_status_financial_products_id_seq', 16, true);


--
-- TOC entry 3432 (class 0 OID 0)
-- Dependencies: 218
-- Name: t_type_transactions_type_transactions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.t_type_transactions_type_transactions_id_seq', 1, false);


--
-- TOC entry 3433 (class 0 OID 0)
-- Dependencies: 220
-- Name: t_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.t_user_id_seq', 14, true);


--
-- TOC entry 3434 (class 0 OID 0)
-- Dependencies: 210
-- Name: user_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.user_user_id_seq', 5, true);


--
-- TOC entry 3233 (class 2606 OID 91630)
-- Name: spring_session_attributes spring_session_attributes_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.spring_session_attributes
    ADD CONSTRAINT spring_session_attributes_pk PRIMARY KEY (session_primary_id, attribute_name);


--
-- TOC entry 3231 (class 2606 OID 91620)
-- Name: spring_session spring_session_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.spring_session
    ADD CONSTRAINT spring_session_pk PRIMARY KEY (primary_id);


--
-- TOC entry 3248 (class 2606 OID 91801)
-- Name: t_account_transations t_account_transations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.t_account_transations
    ADD CONSTRAINT t_account_transations_pkey PRIMARY KEY (account_transactions_id);


--
-- TOC entry 3235 (class 2606 OID 91749)
-- Name: t_financial_products t_financial_products_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.t_financial_products
    ADD CONSTRAINT t_financial_products_pkey PRIMARY KEY (financial_products_id);


--
-- TOC entry 3237 (class 2606 OID 91756)
-- Name: t_history_active_user t_history_active_user_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.t_history_active_user
    ADD CONSTRAINT t_history_active_user_pkey PRIMARY KEY (history_active_user_id);


--
-- TOC entry 3239 (class 2606 OID 91761)
-- Name: t_role t_role_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.t_role
    ADD CONSTRAINT t_role_pkey PRIMARY KEY (id);


--
-- TOC entry 3250 (class 2606 OID 91810)
-- Name: t_status_financial_products t_status_financial_products_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.t_status_financial_products
    ADD CONSTRAINT t_status_financial_products_pkey PRIMARY KEY (status_financial_products_id);


--
-- TOC entry 3241 (class 2606 OID 91768)
-- Name: t_type_transactions t_type_transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.t_type_transactions
    ADD CONSTRAINT t_type_transactions_pkey PRIMARY KEY (type_transactions_id);


--
-- TOC entry 3244 (class 2606 OID 91777)
-- Name: t_user t_user_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.t_user
    ADD CONSTRAINT t_user_pkey PRIMARY KEY (id);


--
-- TOC entry 3246 (class 2606 OID 91782)
-- Name: t_user_roles t_user_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.t_user_roles
    ADD CONSTRAINT t_user_roles_pkey PRIMARY KEY (user_id, roles_id);


--
-- TOC entry 3226 (class 2606 OID 42293)
-- Name: t_old_user user_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.t_old_user
    ADD CONSTRAINT user_pk PRIMARY KEY (user_id);


--
-- TOC entry 3227 (class 1259 OID 91621)
-- Name: spring_session_ix1; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX spring_session_ix1 ON public.spring_session USING btree (session_id);


--
-- TOC entry 3228 (class 1259 OID 91622)
-- Name: spring_session_ix2; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX spring_session_ix2 ON public.spring_session USING btree (expiry_time);


--
-- TOC entry 3229 (class 1259 OID 91623)
-- Name: spring_session_ix3; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX spring_session_ix3 ON public.spring_session USING btree (principal_name);


--
-- TOC entry 3242 (class 1259 OID 99841)
-- Name: t_user_login_uindex; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX t_user_login_uindex ON public.t_user USING btree (login);


--
-- TOC entry 3258 (class 2620 OID 99818)
-- Name: spring_session save_history_active_after; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER save_history_active_after AFTER UPDATE ON public.spring_session FOR EACH ROW EXECUTE FUNCTION public.save_history_active();


--
-- TOC entry 3255 (class 2606 OID 99808)
-- Name: t_account_transations fk9aric8jf1um0f01tsxtyu7pot; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.t_account_transations
    ADD CONSTRAINT fk9aric8jf1um0f01tsxtyu7pot FOREIGN KEY (t_user_id) REFERENCES public.t_user(id);


--
-- TOC entry 3256 (class 2606 OID 91816)
-- Name: t_status_financial_products fkiv6v43iaucnjnvv2hkp5xawrr; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.t_status_financial_products
    ADD CONSTRAINT fkiv6v43iaucnjnvv2hkp5xawrr FOREIGN KEY (financial_products_financial_products_id) REFERENCES public.t_financial_products(financial_products_id);


--
-- TOC entry 3252 (class 2606 OID 91783)
-- Name: t_user_roles fkj47yp3hhtsoajht9793tbdrp4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.t_user_roles
    ADD CONSTRAINT fkj47yp3hhtsoajht9793tbdrp4 FOREIGN KEY (roles_id) REFERENCES public.t_role(id);


--
-- TOC entry 3254 (class 2606 OID 91811)
-- Name: t_account_transations fkkivy2vbvxwlkghkkiccge9g1q; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.t_account_transations
    ADD CONSTRAINT fkkivy2vbvxwlkghkkiccge9g1q FOREIGN KEY (type_transactions_type_transactions_id) REFERENCES public.t_type_transactions(type_transactions_id);


--
-- TOC entry 3257 (class 2606 OID 99813)
-- Name: t_status_financial_products fko19l3kh27p9dfd7qsvebdp9gr; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.t_status_financial_products
    ADD CONSTRAINT fko19l3kh27p9dfd7qsvebdp9gr FOREIGN KEY (t_user_id) REFERENCES public.t_user(id);


--
-- TOC entry 3253 (class 2606 OID 91788)
-- Name: t_user_roles fkpqntgokae5e703qb206xvfdk3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.t_user_roles
    ADD CONSTRAINT fkpqntgokae5e703qb206xvfdk3 FOREIGN KEY (user_id) REFERENCES public.t_user(id);


--
-- TOC entry 3251 (class 2606 OID 91631)
-- Name: spring_session_attributes spring_session_attributes_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.spring_session_attributes
    ADD CONSTRAINT spring_session_attributes_fk FOREIGN KEY (session_primary_id) REFERENCES public.spring_session(primary_id) ON DELETE CASCADE;


-- Completed on 2022-06-11 13:57:35

--
-- PostgreSQL database dump complete
--

