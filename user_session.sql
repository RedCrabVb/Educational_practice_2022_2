create table public.user_session
(
	session_id integer,
	user_id integer,
	expiration_date date,
	last_active timestamp
);

alter table public.user_session owner to root;

