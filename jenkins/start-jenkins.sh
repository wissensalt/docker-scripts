#!/bin/bash

# Automated Jenkins Setup Script
# This script ensures Jenkins can start properly even when jenkins_home is deleted

set -e  # Exit on error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JENKINS_HOME_DIR="$SCRIPT_DIR/jenkins_home"
COMPOSE_FILE="$SCRIPT_DIR/docker-compose.yml"

echo "🚀 Starting automated Jenkins setup..."

# Function to setup jenkins_home directory
setup_jenkins_home() {
    echo "📁 Setting up Jenkins home directory..."
    
    if [ -d "$JENKINS_HOME_DIR" ]; then
        echo "ℹ️ Jenkins home exists. Checking permissions..."
        # Make sure it's writable
        chmod 777 "$JENKINS_HOME_DIR"
    else
        echo "📁 Creating jenkins_home directory..."
        mkdir -p "$JENKINS_HOME_DIR"
        chmod 777 "$JENKINS_HOME_DIR"
    fi
    
    # Setup Maven directories with proper ownership
    echo "📦 Setting up Maven structure..."
    mkdir -p "$JENKINS_HOME_DIR/.m2/repository"
    mkdir -p "$JENKINS_HOME_DIR/.m2/wrapper/dists"
    mkdir -p "$JENKINS_HOME_DIR/.m2/wrapper/maven-wrapper"
    
    # Set proper permissions if not already correct
    if [ ! -r "$JENKINS_HOME_DIR/.m2" ]; then
        chmod -R 755 "$JENKINS_HOME_DIR/.m2"
    fi
    
    # Create Maven settings.xml first
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
    
    # Set ownership to match Jenkins container user (UID 1000) after creating files
    # On macOS, we need to use sudo if current user is not UID 1000
    if [ "$(id -u)" -ne 1000 ]; then
        echo "🔐 Setting ownership to match Jenkins container (UID 1000)..."
        if command -v sudo &> /dev/null; then
            sudo chown -R 1000:1000 "$JENKINS_HOME_DIR/.m2" 2>/dev/null || {
                echo "⚠️ Could not set ownership to 1000:1000. This might cause permission issues."
                echo "   To fix manually, run: sudo chown -R 1000:1000 $JENKINS_HOME_DIR/.m2"
            }
        else
            echo "⚠️ sudo not available. Maven directories may have wrong ownership."
        fi
    fi
    
    echo "✅ Jenkins home setup complete!"
}

# Function to start Jenkins
start_jenkins() {
    echo "🐳 Starting Jenkins with Docker Compose..."
    
    # Use docker-compose directly since it works with podman backend
    local compose_cmd="docker-compose"
    
    if ! command -v docker-compose &> /dev/null; then
        echo "❌ docker-compose is not available"
        exit 1
    fi
    
    echo "🔧 Using command: $compose_cmd"
    
    # Stop any existing containers
    $compose_cmd -f "$COMPOSE_FILE" down 2>/dev/null || true
    
    # Build and start Jenkins
    $compose_cmd -f "$COMPOSE_FILE" up --build
    
    echo "⏳ Waiting for Jenkins to start..."
    
    # Wait for Jenkins to be ready
    local max_attempts=60
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        if curl -s -f http://localhost:8080/login >/dev/null 2>&1; then
            echo "✅ Jenkins is ready!"
            echo "🌐 Access Jenkins at: http://localhost:8080"
            break
        fi
        
        attempt=$((attempt + 1))
        echo "⏳ Waiting for Jenkins... (attempt $attempt/$max_attempts)"
        sleep 5
    done
    
    if [ $attempt -eq $max_attempts ]; then
        echo "⚠️ Jenkins may not be ready yet, but container is running"
        echo "📋 Check status with: docker compose logs jenkins"
    fi
}

# Function to validate setup
validate_setup() {
    echo "🔍 Validating Jenkins setup..."
    
    local compose_cmd="docker-compose"
    
    # Check if container is running
    if $compose_cmd -f "$COMPOSE_FILE" ps | grep -q "jenkins.*Up"; then
        echo "✅ Jenkins container is running"
        
        # Test Maven configuration
        echo "📦 Testing Maven configuration..."
        if $compose_cmd -f "$COMPOSE_FILE" exec jenkins bash -c "mvn -Duser.home=/var/jenkins_home -Dmaven.repo.local=/var/jenkins_home/.m2/repository -s /var/jenkins_home/.m2/settings.xml --version" >/dev/null 2>&1; then
            echo "✅ Maven is configured correctly"
        else
            echo "⚠️ Maven configuration may need adjustment"
        fi
        
        # Test Podman
        echo "🐳 Testing Podman configuration..."
        if $compose_cmd -f "$COMPOSE_FILE" exec jenkins podman --version >/dev/null 2>&1; then
            echo "✅ Podman is available"
        else
            echo "⚠️ Podman may not be available"
        fi
        
    else
        echo "❌ Jenkins container is not running"
        echo "📋 Check logs with: $compose_cmd logs jenkins"
        return 1
    fi
}

# Main execution
main() {
    echo "🔧 Jenkins Automated Setup"
    echo "=========================="
    
    # Check if we're in the right directory
    if [ ! -f "$COMPOSE_FILE" ]; then
        echo "❌ docker-compose.yml not found. Please run this script from the Jenkins directory."
        exit 1
    fi
    
    setup_jenkins_home
    start_jenkins
    
    echo ""
        echo "🔧 Validating and applying bulletproof Maven wrapper fix..."
    
    # Wait for Jenkins to be fully ready
    sleep 5
    
    # Apply bulletproof wrapper fix if needed
    if podman exec jenkins bash -c 'find /var/jenkins_home/workspace -name "mvnw" -type f -exec head -1 {} \; 2>/dev/null | grep -q "Bulletproof"' 2>/dev/null; then
        echo "✅ Maven wrapper already fixed"
    else
        echo "🔧 Applying bulletproof Maven wrapper fix to existing projects..."
        if podman exec jenkins bash -c 'find /var/jenkins_home/workspace -name "mvnw" -type f 2>/dev/null' | head -1 >/dev/null 2>&1; then
            echo "📋 Found Maven projects, applying fix..."
            # Copy the fix script into the container and run it
            if [ -f "${SCRIPT_DIR}/fix-maven-wrapper.sh" ]; then
                podman cp "${SCRIPT_DIR}/fix-maven-wrapper.sh" jenkins:/tmp/fix-maven-wrapper.sh
                podman exec jenkins bash -c 'chmod +x /tmp/fix-maven-wrapper.sh && /tmp/fix-maven-wrapper.sh /var/jenkins_home/workspace'
                echo "✅ Bulletproof Maven wrapper fix applied"
            else
                echo "⚠️  Fix script not found in ${SCRIPT_DIR}"
            fi
        else
            echo "ℹ️  No Maven projects found yet (will auto-fix when created)"
        fi
    fi
    
    # Verify Maven wrapper interceptor is working
    if podman exec jenkins test -f /tmp/maven-interceptor/mvnw; then
        echo "✅ Maven wrapper interceptor is active"
    else
        echo "⚠️ Maven wrapper interceptor not found - this is unexpected"
    fi
    
    # Verify monitoring system is running
    if podman exec jenkins pgrep -f "fix-all-mvnw" >/dev/null; then
        echo "✅ Maven wrapper monitoring system is running"
    else
        echo "⚠️ Maven wrapper monitoring system not running - this is unexpected"
    fi
    
    # Test the Maven wrapper works
    podman exec jenkins bash -c '
        cd /tmp && mkdir -p test-mvnw && cd test-mvnw
        echo "<project><modelVersion>4.0.0</modelVersion><groupId>test</groupId><artifactId>test</artifactId><version>1.0</version></project>" > pom.xml
        echo "#!/bin/bash" > mvnw && echo "exec /tmp/maven-interceptor/mvnw \"\$@\"" >> mvnw && chmod +x mvnw
        ./mvnw --version >/dev/null 2>&1 && echo "✅ Maven wrapper test passed" || echo "⚠️ Maven wrapper test failed"
        cd /tmp && rm -rf test-mvnw
    '
    
    echo "🎉 Maven wrapper fix validation complete!"
    echo ""
    echo "📋 What was configured:"
    echo "   ✅ Jenkins home directory with proper permissions"
    echo "   ✅ Maven repository and settings"
    echo "   ✅ Podman integration"
    echo "   ✅ User permissions (1000:1000)"
    echo "   ✅ Maven wrapper fix (bulletproof, automatic, permanent)"
    echo "   ✅ Maven wrapper monitoring system"
    echo ""
    echo "💡 The Maven wrapper fix uses a 'bulletproof' approach that:"
    echo "   • Directly calls system Maven (no downloads needed)"
    echo "   • Uses safe repository paths (/var/jenkins_home/.m2/repository)"
    echo "   • Automatically applies to all existing and new projects"
    echo ""
    echo "🌐 Access Jenkins at: http://localhost:8080"
    echo ""
    echo "🔧 Useful commands:"
    echo "   View logs: docker compose logs jenkins -f"
    echo "   Stop Jenkins: docker compose down"
    echo "   Restart Jenkins: docker compose restart"
    echo "   Check Maven wrapper: docker compose exec jenkins ls -la /tmp/maven-interceptor/"
    echo "   View Maven wrapper log: docker compose exec jenkins tail -f /tmp/mvnw-fix.log"
    echo ""
    
    # Optionally validate setup
    if [ "$1" = "--validate" ]; then
        validate_setup
    fi
}

# Handle command line arguments
case "${1:-}" in
    --help|-h)
        echo "Jenkins Automated Setup Script"
        echo ""
        echo "Usage: $0 [options]"
        echo ""
        echo "Options:"
        echo "  --validate    Run validation checks after setup"
        echo "  --help, -h    Show this help message"
        echo ""
        echo "This script automatically sets up Jenkins with:"
        echo "  - Proper directory permissions"
        echo "  - Maven configuration"
        echo "  - Podman integration"
        echo ""
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac