-- create user replicator with replication encrypted password 'replicator_password';
-- select pg_create_physical_replication_slot('replication_slot');

-- Modified script
create database account;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO repl_user;
create database rbac;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO repl_user;
create database business;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO repl_user;
create database pos;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO repl_user;
create database location;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO repl_user;