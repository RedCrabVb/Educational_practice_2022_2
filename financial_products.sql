create table public.financial_products
(
	financial_products_id serial not null
		constraint financial_products_pk
			primary key,
	title varchar(255) not null,
	description text not null
);

comment on table public.financial_products is 'Финансовые продукты';

alter table public.financial_products owner to root;

