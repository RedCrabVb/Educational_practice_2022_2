create table public.account_transactions
(
	account_transactions_id serial not null
		constraint account_transactions_pk
			primary key
		constraint account_transactions_type_transactions_type_transactions_id_fk
			references public.type_transactions,
	type_transactions_id integer,
	amount integer not null,
	currency varchar(100) not null,
	user_id integer
);

comment on table public.account_transactions is 'операции по счету';

alter table public.account_transactions owner to root;

