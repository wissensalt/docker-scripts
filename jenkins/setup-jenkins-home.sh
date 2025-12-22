#!/bin/bash

# Jenkins Home Setup Script
# This script automatically sets up the jenkins_home directory with proper permissions

JENKINS_HOME_DIR="./jenkins_home"
JENKINS_UID=1000
JENKINS_GID=1000

echo "🔧 Setting up Jenkins home directory..."

# Create jenkins_home if it doesn't exist
if [ ! -d "$JENKINS_HOME_DIR" ]; then
    echo "📁 Creating jenkins_home directory..."
    mkdir -p "$JENKINS_HOME_DIR"
else
    echo "📁 jenkins_home directory already exists"
fi

# Set proper permissions (temporarily open for initialization)
echo "🔐 Setting permissions for Jenkins initialization..."
chmod 777 "$JENKINS_HOME_DIR"

# Create Maven directories structure
echo "📦 Setting up Maven directories..."
mkdir -p "$JENKINS_HOME_DIR/.m2/repository"
mkdir -p "$JENKINS_HOME_DIR/.m2/wrapper/dists"
mkdir -p "$JENKINS_HOME_DIR/.m2/wrapper/maven-wrapper"
chmod -R 755 "$JENKINS_HOME_DIR/.m2"

# Create Maven settings.xml
echo "⚙️ Creating Maven settings.xml..."
cat > "$JENKINS_HOME_DIR/.m2/settings.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<settings xmlns="http://maven.apache.org/SETTINGS/1.0.0"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.0.0
                              http://maven.apache.org/xsd/settings-1.0.0.xsd">
  <localRepository>/var/jenkins_home/.m2/repository</localRepository>
</settings>
EOF

# Set ownership to Jenkins user (if running with sudo/root)
if [ "$EUID" -eq 0 ]; then
    echo "👤 Setting ownership to Jenkins user ($JENKINS_UID:$JENKINS_GID)..."
    chown -R $JENKINS_UID:$JENKINS_GID "$JENKINS_HOME_DIR"
else
    echo "ℹ️ Run with sudo to set proper ownership, or let Jenkins handle it automatically"
fi

echo "✅ Jenkins home setup complete!"
echo "📋 Directory structure:"
ls -la "$JENKINS_HOME_DIR/" 2>/dev/null || echo "Directory will be populated when Jenkins starts"