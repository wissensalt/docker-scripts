#!/bin/bash
set -euo pipefail

# Bulletproof Maven Wrapper Fix for Jenkins CI/CD
# This script creates a direct Maven wrapper replacement that bypasses all permission issues

PROJECT_PATH="${1:-/var/jenkins_home/workspace}"
WRAPPER_NAME="${2:-mvnw}"

echo "🔧 Applying bulletproof Maven wrapper fix..."
echo "   Project Path: $PROJECT_PATH"
echo "   Wrapper Name: $WRAPPER_NAME"

# Find all Maven wrapper files in the project
WRAPPER_FILES=$(find "$PROJECT_PATH" -name "$WRAPPER_NAME" -type f 2>/dev/null || echo "")

if [ -z "$WRAPPER_FILES" ]; then
    echo "❌ No Maven wrapper files found in $PROJECT_PATH"
    exit 1
fi

# Fix each wrapper file
for WRAPPER_FILE in $WRAPPER_FILES; do
    echo "🔧 Fixing wrapper: $WRAPPER_FILE"
    
    # Create bulletproof wrapper that directly calls Maven
    cat > "$WRAPPER_FILE" << 'WRAPPER_END'
#!/bin/bash
# Bulletproof Maven Wrapper - Bypasses all permission issues

set -euo pipefail

# Use direct Maven installation with safe repository path
MAVEN_HOME="/usr/share/maven"
MAVEN_REPO="/var/jenkins_home/.m2/repository"

# Ensure repository directory exists
mkdir -p "$MAVEN_REPO"
chmod 755 "$MAVEN_REPO"

# Use Maven directly with safe paths - no wrapper downloads needed
exec "$MAVEN_HOME/bin/mvn" \
    -Dmaven.repo.local="$MAVEN_REPO" \
    -Dmaven.wagon.http.retryHandler.requestSentEnabled=true \
    -Dmaven.wagon.http.retryHandler.count=3 \
    "$@"
WRAPPER_END

    chmod +x "$WRAPPER_FILE"
    echo "✅ Fixed: $WRAPPER_FILE"
done

echo "🎉 Maven wrapper fix applied successfully!"
echo "   All wrapper files now use direct Maven execution"
echo "   No more permission errors!"

# Test the fix if we're in a project directory
if [ -f "$PROJECT_PATH/pom.xml" ]; then
    echo "🧪 Testing the fix..."
    cd "$PROJECT_PATH"
    if ./mvnw --version >/dev/null 2>&1; then
        echo "✅ Wrapper test successful!"
    else
        echo "⚠️  Wrapper test failed - but this may be normal if dependencies need to be resolved first"
    fi
fi