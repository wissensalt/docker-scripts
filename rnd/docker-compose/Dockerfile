FROM openjdk:8u212-jdk-alpine3.9

# copy jar file into /bin directory and give it name as app.jar
COPY target/*.jar /bin/app.jar

# chage directory to /bin
WORKDIR /bin

# starting entry point
ENTRYPOINT ["java", "-jar", "app.jar"]

# expose port 8080 as tcp protocol
EXPOSE 8080/tcp