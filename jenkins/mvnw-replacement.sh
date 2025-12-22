#!/bin/bash

# Maven Wrapper Replacement Script
# This script provides a drop-in replacement for ./mvnw that works around 
# the Maven wrapper permission issues on macOS with Podman

# Set Maven options to use explicit paths and avoid permission issues
export MAVEN_OPTS="-Dmaven.repo.local=/tmp/m2-repository"
export MAVEN_USER_HOME="/tmp/m2-config"

# Create temporary Maven directories with proper permissions
mkdir -p /tmp/m2-repository
mkdir -p /tmp/m2-config

# Copy Maven settings if they exist
if [ -f "/var/jenkins_home/.m2/settings.xml" ]; then
    cp /var/jenkins_home/.m2/settings.xml /tmp/m2-config/settings.xml 2>/dev/null || true
fi

# Run Maven with explicit settings
exec mvn \
    -Dmaven.repo.local=/tmp/m2-repository \
    -gs /tmp/m2-config/settings.xml \
    "$@"