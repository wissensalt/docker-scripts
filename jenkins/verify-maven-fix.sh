#!/bin/bash

# Maven Wrapper Fix Verification Script
# This script verifies that the Maven wrapper permission fix is working correctly

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🧪 Maven Wrapper Fix Verification"
echo "=================================="

# Check if Jenkins is running
if ! docker-compose ps jenkins | grep -q "Up"; then
    echo "❌ Jenkins container is not running"
    echo "   Run ./start-jenkins.sh first"
    exit 1
fi

echo "✅ Jenkins container is running"

# Check Maven wrapper interceptor
echo "🔍 Checking Maven wrapper interceptor..."
if podman exec jenkins test -f /tmp/maven-interceptor/mvnw; then
    echo "✅ Maven wrapper interceptor exists"
    podman exec jenkins ls -la /tmp/maven-interceptor/mvnw
else
    echo "❌ Maven wrapper interceptor not found"
    exit 1
fi

# Check monitoring system
echo "🔍 Checking monitoring system..."
if podman exec jenkins pgrep -f "fix-all-mvnw" >/dev/null; then
    echo "✅ Maven wrapper monitoring system is running"
    echo "   Process: $(podman exec jenkins pgrep -f "fix-all-mvnw")"
else
    echo "❌ Maven wrapper monitoring system not running"
    exit 1
fi

# Test Maven wrapper functionality
echo "🔍 Testing Maven wrapper functionality..."
podman exec jenkins bash -c '
    cd /var/jenkins_home/workspace
    rm -rf mvnw-test 2>/dev/null
    mkdir mvnw-test && cd mvnw-test
    
    # Create a test project
    echo "<project><modelVersion>4.0.0</modelVersion><groupId>test</groupId><artifactId>test-app</artifactId><version>1.0</version></project>" > pom.xml
    
    # Create a problematic mvnw file
    cat > mvnw << "EOF"
#!/bin/bash
echo "This would cause AccessDeniedException"
exit 1
EOF
    chmod +x mvnw
    
    echo "Created problematic wrapper in workspace, waiting for fix..."
    sleep 8
    
    # Check if it was fixed
    if grep -q "exec /tmp/maven-interceptor/mvnw" mvnw; then
        echo "✅ Wrapper was automatically fixed"
        # Test it works
        ./mvnw --version >/dev/null && echo "✅ Fixed wrapper executes successfully"
    else
        echo "❌ Wrapper was not automatically fixed"
        cat mvnw
        exit 1
    fi
    
    cd /var/jenkins_home/workspace && rm -rf mvnw-test
'

# Check logs
echo "🔍 Checking recent monitoring logs..."
podman exec jenkins tail -5 /tmp/mvnw-fix.log 2>/dev/null || echo "No recent activity"

echo ""
echo "🎉 All Maven wrapper fix verifications passed!"
echo ""
echo "💡 Your Jenkins setup will automatically fix any Maven wrapper permission issues."
echo "   Even if you delete jenkins_home, the fix is built into the Docker image."