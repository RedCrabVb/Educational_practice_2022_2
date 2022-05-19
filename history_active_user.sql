create table public.history_active_user
(
	history_active_user_id serial not null
		constraint history_active_user_pk
			primary key,
	last_active timestamp,
	use_session_id integer,
	device_information varchar(255)
);

comment on table public.history_active_user is 'История использования ЛК';

alter table public.history_active_user owner to root;

