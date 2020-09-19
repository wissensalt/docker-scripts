FROM jenkins:alpine
LABEL maintainer="wissensalt@gmail.com"

USER root
RUN mkdir /var/log/jenkins
RUN chown -R  jenkins:jenkins /var/log/jenkins
USER jenkins

ENV JAVA_OPTS="-Xmx8192m"
ENV JENKINS_OPTS=" --handlerCountMax=300 --logfile=/var/log/jenkins/jenkins.log"