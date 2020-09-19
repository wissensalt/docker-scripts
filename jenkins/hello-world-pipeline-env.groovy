pipeline {
    agent any

    stages {
        stage('Hello') {
            steps {
                echo "Hello World $BUILD_NUMBER DEMO $DEMO"
            }
        }
    }

    environment {
        DEMO = '1'
    }
}