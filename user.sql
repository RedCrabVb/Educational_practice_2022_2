create table public."user"
(
	user_id serial not null
		constraint user_pk
			primary key,
	first_name varchar(255) not null,
	last_name varchar(255) not null,
	patronymic varchar(255) not null,
	phone varchar(255) not null,
	mail varchar(255),
	passport integer,
	salt integer,
	hash_password integer,
	amount integer default 0 not null,
	currency varchar(255) default 'RUB'::character varying not null
);

alter table public."user" owner to root;

