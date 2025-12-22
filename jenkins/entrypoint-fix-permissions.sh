#!/bin/bash

# This script ensures proper Maven directory permissions at container startup
# and sets up Maven wrapper interception to fix permission issues

echo "Fixing Maven directory permissions and wrapper setup..."

# Create Maven directories if they don't exist and set proper permissions
if [ ! -d "/var/jenkins_home/.m2" ]; then
    mkdir -p /var/jenkins_home/.m2/repository
    mkdir -p /var/jenkins_home/.m2/wrapper/dists  
    mkdir -p /var/jenkins_home/.m2/wrapper/maven-wrapper
fi

# Try to fix permissions - if it fails due to mount restrictions, it's okay
chmod -R 755 /var/jenkins_home/.m2 2>/dev/null || echo "Could not change permissions (volume mount restriction)"

# Create a global mvnw script that intercepts all ./mvnw calls
echo "Creating Maven wrapper interceptor..."
mkdir -p /tmp/maven-interceptor
cat > /tmp/maven-interceptor/mvnw << 'WRAPPER_EOF'
#!/bin/bash
# Maven Wrapper Interceptor - fixes permission issues on macOS

# Set Maven options to use writable directories
export MAVEN_OPTS="-Dmaven.repo.local=/tmp/m2-repository ${MAVEN_OPTS}"
export MAVEN_USER_HOME="/tmp/m2-config"

# Create temporary Maven directories
mkdir -p /tmp/m2-repository
mkdir -p /tmp/m2-config

# Copy settings if they exist
if [ -f "/var/jenkins_home/.m2/settings.xml" ]; then
    cp /var/jenkins_home/.m2/settings.xml /tmp/m2-config/settings.xml 2>/dev/null || true
fi

# Run Maven with proper settings
exec mvn -Dmaven.repo.local=/tmp/m2-repository -gs /tmp/m2-config/settings.xml "$@"
WRAPPER_EOF

chmod +x /tmp/maven-interceptor/mvnw

# Add interceptor directory to PATH so ./mvnw finds our script
export PATH="/tmp/maven-interceptor:$PATH"

# Create a function to override ./mvnw calls in shell scripts
# This creates an alias that will be used by Jenkins shell steps
echo 'alias ./mvnw="/tmp/maven-interceptor/mvnw"' > /tmp/mvnw-alias.sh
echo 'export PATH="/tmp/maven-interceptor:$PATH"' >> /tmp/mvnw-alias.sh
chmod +x /tmp/mvnw-alias.sh

echo "Maven wrapper interceptor created and added to PATH"

# Create permanent Maven wrapper replacement system
echo "Setting up permanent Maven wrapper replacement..."
cat > /tmp/fix-all-mvnw.sh << 'FIX_SCRIPT'
#!/bin/bash
# Permanent Maven Wrapper Fix - replaces ALL mvnw files automatically

# Function to replace mvnw files with our fixed version
replace_mvnw_files() {
    local search_dirs="/var/jenkins_home/workspace /var/jenkins_home/jobs"
    
    for search_dir in $search_dirs; do
        if [ -d "$search_dir" ]; then
            find "$search_dir" -name "mvnw" -type f 2>/dev/null | while read mvnw_file; do
                # Check if it's already our fixed version
                if ! grep -q "exec /tmp/maven-interceptor/mvnw" "$mvnw_file" 2>/dev/null; then
                    echo "Fixing Maven wrapper: $mvnw_file"
                    # Backup original if it doesn't exist
                    [ ! -f "${mvnw_file}.original" ] && cp "$mvnw_file" "${mvnw_file}.original" 2>/dev/null
                    # Replace with our fixed version
                    cat > "$mvnw_file" << 'MVNW_FIXED'
#!/bin/bash
# Fixed Maven Wrapper - uses permission-safe directories
exec /tmp/maven-interceptor/mvnw "$@"
MVNW_FIXED
                    chmod +x "$mvnw_file"
                fi
            done
        fi
    done
}

# Initial fix of all existing mvnw files
replace_mvnw_files

# Monitor for new mvnw files and fix them automatically
while true; do
    sleep 5
    replace_mvnw_files
done
FIX_SCRIPT

chmod +x /tmp/fix-all-mvnw.sh

# Start the Maven wrapper monitor in background
nohup /tmp/fix-all-mvnw.sh > /tmp/mvnw-fix.log 2>&1 &

echo "Permanent Maven wrapper fix active - monitoring all workspace directories"

# Create immediate Maven wrapper fix for Jenkins builds
echo "Creating immediate Maven wrapper fix for Jenkins pipelines..."
cat > /usr/local/bin/fix-mvnw-now << 'IMMEDIATE_FIX'
#!/bin/bash
# Immediate Maven wrapper fix - runs before any Maven command

# Fix all mvnw files in current directory and subdirectories
find . -name "mvnw" -type f 2>/dev/null | while read mvnw_file; do
    if ! grep -q "exec /tmp/maven-interceptor/mvnw" "$mvnw_file" 2>/dev/null; then
        echo "Immediately fixing Maven wrapper: $mvnw_file"
        # Backup original
        cp "$mvnw_file" "${mvnw_file}.backup" 2>/dev/null
        # Replace with fixed version
        cat > "$mvnw_file" << 'MVNW_IMMEDIATE'
#!/bin/bash
# Immediately Fixed Maven Wrapper
exec /tmp/maven-interceptor/mvnw "$@"
MVNW_IMMEDIATE
        chmod +x "$mvnw_file"
        echo "Fixed: $mvnw_file"
    fi
done
IMMEDIATE_FIX

chmod +x /usr/local/bin/fix-mvnw-now

# Create a wrapper script that Jenkins will use instead of direct mvnw
cat > /usr/local/bin/jenkins-mvnw << 'JENKINS_WRAPPER'
#!/bin/bash
# Jenkins Maven Wrapper - automatically fixes permission issues

# First, fix any mvnw files in the current workspace
/usr/local/bin/fix-mvnw-now

# Then run the Maven wrapper
if [ -f "./mvnw" ]; then
    ./mvnw "$@"
else
    # Fallback to our interceptor if no local mvnw
    /tmp/maven-interceptor/mvnw "$@"
fi
JENKINS_WRAPPER

chmod +x /usr/local/bin/jenkins-mvnw

echo "Immediate Maven wrapper fix system ready"
echo "Maven directory permissions setup complete."

# Execute the original Jenkins entrypoint
exec /usr/local/bin/jenkins.sh "$@"