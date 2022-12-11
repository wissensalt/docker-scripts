create table stock_card_details
(
	id bigserial not null
		constraint stock_card_details_pkey
			primary key,
	item_id bigint,
	entry_unit integer,
	entry_description varchar,
	out_unit integer,
	out_description varchar,
	quantity integer,
	expired_date date,
	batch_number varchar,
	description varchar,
	created_at timestamp not null,
	updated_at timestamp not null,
	pos_outlet_id bigint,
	id_tbl varchar,
	type varchar,
	liph_date date,
	stock_date timestamp,
	transaction_type varchar,
	transaction_number varchar,
	source_name varchar,
	source_id bigint
);

create index idx_item_id
	on stock_card_details (item_id);

create index idx_liph_date
	on stock_card_details (liph_date);

create index idx_pos_outlet_id
	on stock_card_details (pos_outlet_id);

create index idx_pos_outlet_item
	on stock_card_details (pos_outlet_id, item_id);

create index idx_pos_outlet_item_liph_date
	on stock_card_details (pos_outlet_id asc, item_id asc, liph_date asc, pos_outlet_id asc, item_id asc, stock_date desc);

create index idx_pos_outlet_item_order_stock_date
	on stock_card_details (pos_outlet_id, item_id, stock_date);

create index idx_pos_outlet_item_stock_date_updated_at
	on stock_card_details (pos_outlet_id asc, item_id asc, stock_date asc, updated_at desc);

create index idx_source_id
	on stock_card_details (source_id);

create index idx_source_name
	on stock_card_details (source_name);

create index idx_stock_by_date_item_outlet
	on stock_card_details (pos_outlet_id, item_id, liph_date, id, stock_date);

create index idx_stock_by_item_outlet
	on stock_card_details (pos_outlet_id, item_id, id, stock_date);

create index idx_stock_date
	on stock_card_details (stock_date);


create table expired_date_details
(
	id bigserial not null
		constraint expired_date_details_pkey
			primary key,
	expired_date date,
	expired_date_type varchar,
	stock_card_detail_id bigint,
	quantity bigint not null,
	created_at timestamp not null,
	updated_at timestamp not null
);