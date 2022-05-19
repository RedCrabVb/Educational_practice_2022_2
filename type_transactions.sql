create table public.type_transactions
(
	type_transactions_id serial not null
		constraint type_transactions_pk
			primary key,
	name varchar(255)
);

comment on table public.type_transactions is 'Тип транзакций';

alter table public.type_transactions owner to root;

create unique index type_transactions_name_uindex
	on public.type_transactions (name);

