-- INPUT DB
CREATE TABLE test
(
    id    bigserial not null primary key,
    code  varchar(50),
    value varchar(100)
);

CREATE TABLE test_2
(
    id    bigserial not null primary key,
    code  varchar(50),
    value varchar(100)
);

-- GENERATE DATA
insert into test(code, value)
SELECT generate_series(1, 10000) AS code, md5(random()::text) AS value;
insert into test2(code, value)
SELECT generate_series(1, 10000) AS code, md5(random()::text) AS value;

-- CHECK DATA ==> 10000
select count(1) from test;
select count(1) from test_2;