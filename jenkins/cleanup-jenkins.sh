#!/bin/bash

# Jenkins Cleanup Script
# This script safely stops and removes Jenkins data for testing automation

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JENKINS_HOME_DIR="$SCRIPT_DIR/jenkins_home"

echo "🧹 Jenkins Cleanup Script"
echo "========================="

# Stop Jenkins
echo "🛑 Stopping Jenkins containers..."

compose_cmd="docker-compose"
$compose_cmd down 2>/dev/null || echo "No containers to stop"

# Remove jenkins_home directory
if [ -d "$JENKINS_HOME_DIR" ]; then
    echo "🗑️ Removing jenkins_home directory..."
    # Change ownership back to current user before removing (in case it's owned by UID 1000)
    if command -v sudo &> /dev/null; then
        sudo chown -R $(id -u):$(id -g) "$JENKINS_HOME_DIR" 2>/dev/null || true
    fi
    rm -rf "$JENKINS_HOME_DIR"
    echo "✅ jenkins_home removed"
else
    echo "ℹ️ jenkins_home directory does not exist"
fi

# Remove any dangling volumes or images (optional)
if [ "${1:-}" = "--deep" ]; then
    echo "🧹 Deep cleaning Docker resources..."
    docker system prune -f 2>/dev/null || echo "Docker cleanup skipped"
fi

echo ""
echo "✅ Cleanup complete!"
echo ""
echo "🔧 To restart Jenkins, run:"
echo "   ./start-jenkins.sh"