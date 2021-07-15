FROM docker.elastic.co/logstash/logstash:7.3.2
MAINTAINER <wissensalt@gmail.com> Wissensalt

# install deps
RUN /usr/share/logstash/bin/logstash-plugin install logstash-input-jdbc
RUN /usr/share/logstash/bin/logstash-plugin install logstash-output-jdbc
#RUN /usr/share/logstash/bin/logstash-plugin install logstash-filter-aggregate
#RUN /usr/share/logstash/bin/logstash-plugin install logstash-filter-jdbc_streaming
#RUN /usr/share/logstash/bin/logstash-plugin install logstash-filter-mutate

ADD https://jdbc.postgresql.org/download/postgresql-42.2.5.jar /usr/share/logstash/vendor/jar/jdbc/postgresql-42.2.5.jar
USER root
RUN chown -R logstash /usr/share/logstash/vendor/


#input
RUN export INPUT_JDBC_DRIVER_LOCATION=/usr/share/logstash/vendor/jar/jdbc/postgresql-42.2.5.jar
RUN export INPUT_JDBC_DRIVER_CLASS=org.postgresql.Driver
RUN export INPUT_JDBC_URL_CONNECTION=jdbc:postgresql://localhost:5432/test_input_db
RUN export INPUT_JDBC_USERNAME=postgres
RUN export INPUT_JDBC_PASSWORD=pgadmin
RUN export INPUT_STATEMENT="SELECT * FROM test;"

#output:
RUN export OUTPUT_JDBC_DRIVER_LOCATION=/usr/share/logstash/vendor/jar/jdbc/postgresql-42.2.5.jar
RUN export OUTPUT_JDBC_DRIVER_CLASS=org.postgresql.Driver
RUN export OUTPUT_JDBC_URL_CONNECTION=jdbc:postgresql://localhost:5433/test_output_db
RUN export OUTPUT_JDBC_USERNAME=postgres
RUN export OUTPUT_JDBC_PASSWORD=pgadmin
RUN export OUTPUT_STATEMENT="INSERT INTO test(code, name) values ("key", "values");"

COPY logstash.conf /usr/share/logstash/pipeline/
CMD ["logstash", "-f", "/usr/share/logstash/pipeline/logstash.conf"]