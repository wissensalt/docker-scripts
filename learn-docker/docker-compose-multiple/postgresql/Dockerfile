FROM postgres:alpine

ENV POSTGRES_USER=postgres
ENV POSTGRES_PASSWORD=pgadmin
ENV POSTGRES_DB=test_db

COPY *.sql /docker-entrypoint-initdb.d/

EXPOSE 5432/tcp