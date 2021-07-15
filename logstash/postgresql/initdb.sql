-- INPUT DB
CREATE TABLE test
(
    id    bigserial not null primary key,
    code  varchar(50),
    value varchar(100)
);
-- GENERATE DATA
insert into test(code, value)
SELECT generate_series(1, 10000) AS code, md5(random()::text) AS value;
-- CHECK DATA ==> 10000
select count(1) from test;

-- OUTPUT DB
CREATE TABLE test
(
    id    bigserial not null primary key,
    code  varchar(50),
    value varchar(100)
);

-- CHECK DATA AFTER FINISH MIGRATION==> 10000
select count(1) from test;