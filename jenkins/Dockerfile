FROM jenkins/jenkins:lts
LABEL maintainer="wissensalt@gmail.com"

USER root
RUN mkdir /var/log/jenkins
RUN chown -R  jenkins:jenkins /var/log/jenkins

## Start Additional Docker Inside Jenkins
#RUN apt-get update -qq \
#    && apt-get install -qqy apt-transport-https ca-certificates curl gnupg2 software-properties-common 
#RUN curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -
#RUN add-apt-repository \
#   "deb [arch=amd64] https://download.docker.com/linux/debian \
#   $(lsb_release -cs) \
#   stable"
#RUN apt-get update  -qq \
#    && apt-get install docker-ce=17.12.1~ce-0~debian -y

## docker-compose
#RUN curl -L “https://github.com/docker/compose/releases/download/1.25.5/docker-compose-$(uname -s)-$(uname -m)” -o /usr/local/bin/docker-compose && \
# chmod +x /usr/local/bin/docker-compose && \
# ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
## docker compose
## End Additional Docker Inside Jenkins

# Start Additional Docker Inside Jenkins
RUN apt-get -y update && \
    apt-get -y install apt-transport-https ca-certificates curl gnupg-agent software-properties-common && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - && \
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") $(lsb_release -cs) stable" && \
    apt-get update && \
    apt-get -y install docker-ce docker-ce-cli containerd.io
RUN curl -L "https://github.com/docker/compose/releases/download/1.26.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && \
    chmod +x /usr/local/bin/docker-compose && \
    ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
# End Additional Docker Inside Jenkins

RUN usermod -aG docker jenkins


USER jenkins

ENV JAVA_OPTS="-Xmx8192m"
ENV JENKINS_OPTS=" --handlerCountMax=300 --logfile=/var/log/jenkins/jenkins.log"