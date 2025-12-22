pipeline {
    agent any
    
    environment {
        // Override Maven wrapper to use our fixed version
        PATH = "/tmp/maven-interceptor:${env.PATH}"
    }
    
    stages {
        stage('Fix Maven Wrapper') {
            steps {
                script {
                    // Create a local mvnw script that calls our interceptor
                    sh '''
                        # Create local mvnw that calls our interceptor
                        cat > mvnw << 'EOF'
#!/bin/bash
exec /tmp/maven-interceptor/mvnw "$@"
EOF
                        chmod +x mvnw
                    '''
                }
            }
        }
        
        stage('Test Maven Wrapper') {
            steps {
                script {
                    echo "🧪 Testing Maven wrapper fix..."
                    
                    // Test the fixed wrapper
                    sh './mvnw --version'
                    
                    // Test actual Maven command that would fail before
                    sh '''
                        echo "<project><modelVersion>4.0.0</modelVersion><groupId>test</groupId><artifactId>test-app</artifactId><version>1.0</version></project>" > pom.xml
                        ./mvnw validate
                    '''
                    
                    echo "✅ Maven wrapper test completed successfully!"
                }
            }
        }
    }
}