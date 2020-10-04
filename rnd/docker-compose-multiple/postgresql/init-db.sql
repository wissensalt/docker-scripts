-- DEFAULT USING test_db

CREATE TABLE IF NOT EXISTS users (
    id serial PRIMARY KEY,
    email VARCHAR (355) UNIQUE NOT NULL,
    password VARCHAR (50) NOT NULL
);

insert into users(email, password) values ('one@email.com', 'one');
insert into users(email, password) values ('two@email.com', 'two');