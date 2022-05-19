create table public.status_financial_products
(
	status_financial_products_id serial not null
		constraint status_financial_products_pk
			primary key,
	id_user integer,
	financial_products_id integer,
	open_date date not null,
	close_date date not null
);

comment on table public.status_financial_products is 'Статус финансовых продуктов';

alter table public.status_financial_products owner to root;

