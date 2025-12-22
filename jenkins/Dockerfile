FROM jenkins/jenkins:jdk21

# Switch to root to install Docker
USER root

RUN apt-get update

# Install Podman and Buildah (Buildah is better for CI/CD)
RUN apt-get install -y podman buildah

# Install additional tools that might be useful
RUN apt-get install -y \
    git \
    curl \
    wget \
    unzip \
    jq \
    gettext-base \
    maven

# Add Jenkins user to podman group
RUN groupadd podman && usermod -aG podman jenkins

# Configure subuid and subgid for the jenkins user (avoiding overlapping ranges)
RUN echo "jenkins:165536:65536" >> /etc/subuid
RUN echo "jenkins:165536:65536" >> /etc/subgid

# Create containers.conf for rootless podman
RUN mkdir -p /var/jenkins_home/.config/containers
COPY containers.conf /var/jenkins_home/.config/containers/containers.conf
COPY storage.conf /var/jenkins_home/.config/containers/storage.conf
COPY registries.conf /var/jenkins_home/.config/containers/registries.conf

# Set up proper permissions for subuid/subgid
RUN chmod 644 /etc/subuid /etc/subgid

# Create podman storage directory
RUN mkdir -p /var/jenkins_home/.local/share/containers

# Switch back to jenkins user first
USER jenkins

# Create Maven repository directory and configure Maven as jenkins user
RUN mkdir -p /var/jenkins_home/.m2/repository
RUN mkdir -p /var/jenkins_home/.m2/wrapper/dists
RUN mkdir -p /var/jenkins_home/.m2/wrapper/maven-wrapper
RUN chmod -R 755 /var/jenkins_home/.m2

# Copy custom entrypoint script and Maven wrapper replacement
COPY entrypoint-fix-permissions.sh /usr/local/bin/entrypoint-fix-permissions.sh
COPY mvnw-replacement.sh /usr/local/bin/mvnw

# Switch to root to set permissions for entrypoint and final ownership
USER root
RUN chmod +x /usr/local/bin/entrypoint-fix-permissions.sh
RUN chmod +x /usr/local/bin/mvnw
RUN chown -R jenkins:jenkins /var/jenkins_home/.config /var/jenkins_home/.local

# Add Maven wrapper interceptor to global PATH
RUN ln -sf /usr/local/bin/mvnw /usr/local/bin/mvnw-global

# Set custom entrypoint  
ENTRYPOINT ["/usr/local/bin/entrypoint-fix-permissions.sh"]

# Add environment variable for Maven wrapper interception
ENV PATH="/tmp/maven-interceptor:$PATH"

# Switch back to jenkins user
USER jenkins

# Set Maven home environment variables
ENV MAVEN_USER_HOME=/var/jenkins_home/.m2
ENV MAVEN_CONFIG=/var/jenkins_home/.m2

# Install Jenkins plugins (optional, but recommended for Docker integration)
# Maven Integration Plugin
# Git
# Github
# Docker Pipeline
# Configuration as Code
# Blue Ocean
# Pipeline: Stage View
# Credentials Binding
# SSH Credentials
RUN jenkins-plugin-cli --plugins \
    maven-plugin \
    git \
    github \
    docker-workflow \
    configuration-as-code \
    blueocean \
    pipeline-stage-view \
    credentials-binding \
    ssh-credentials \
    timestamper

