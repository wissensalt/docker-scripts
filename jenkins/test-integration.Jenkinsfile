pipeline {
    agent any
    
    stages {
        stage('Test Maven Wrapper Fix') {
            steps {
                script {
                    echo "🔧 Testing Maven Wrapper Solutions..."
                    
                    // Test 1: System Maven (always works)
                    echo "✅ Testing system Maven..."
                    sh 'mvn --version'
                    
                    // Test 2: Maven wrapper replacement script  
                    echo "✅ Testing Maven wrapper replacement..."
                    sh '/usr/local/bin/mvnw --version'
                    
                    // Test 3: Create a simple test project to verify functionality
                    echo "✅ Testing Maven functionality..."
                    sh '''
                        # Create a temporary test directory
                        cd /tmp
                        rm -rf maven-test 2>/dev/null || true
                        
                        # Create a simple Maven project structure
                        mkdir -p maven-test/src/main/java/com/example
                        cd maven-test
                        
                        # Create a minimal pom.xml
                        cat > pom.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 
         http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <groupId>com.example</groupId>
    <artifactId>test-app</artifactId>
    <version>1.0-SNAPSHOT</version>
    <properties>
        <maven.compiler.source>21</maven.compiler.source>
        <maven.compiler.target>21</maven.compiler.target>
    </properties>
</project>
EOF
                        
                        # Test Maven wrapper replacement with a real command
                        /usr/local/bin/mvnw validate
                        
                        echo "🎉 All Maven tests passed!"
                    '''
                }
            }
        }
        
        stage('Test Podman Integration') {
            steps {
                script {
                    echo "🐳 Testing Podman integration..."
                    sh '''
                        # Test basic Podman functionality
                        podman --version
                        
                        # Test image building (simple example)
                        cd /tmp
                        rm -rf docker-test 2>/dev/null || true
                        mkdir docker-test
                        cd docker-test
                        
                        # Create a simple Dockerfile
                        cat > Dockerfile << 'EOF'
FROM docker.io/library/alpine:latest
RUN echo "Hello from Podman build!"
CMD ["echo", "Container works!"]
EOF
                        
                        # Build and test the image
                        podman build -t test-image:latest .
                        podman run --rm test-image:latest
                        
                        # Clean up
                        podman rmi test-image:latest
                        
                        echo "🎉 Podman integration test passed!"
                    '''
                }
            }
        }
    }
}