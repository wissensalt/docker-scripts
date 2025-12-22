# Jenkins Automated Setup

This directory contains scripts to automate the setup and management of Jenkins with Podman integration.

## 🚀 Quick Start

### Start Jenkins (Automated)
```bash
./start-jenkins.sh
```
This script will automatically:
- Create `jenkins_home` directory with proper permissions
- Set up Maven repository and configuration
- Start Jenkins with Podman integration
- Wait for Jenkins to be ready

### Clean Up and Restart
```bash
./cleanup-jenkins.sh
./start-jenkins.sh
```

## 📁 Files

### Scripts
- **`start-jenkins.sh`** - Main automation script for setting up and starting Jenkins
- **`setup-jenkins-home.sh`** - Standalone script for just setting up the jenkins_home directory
- **`cleanup-jenkins.sh`** - Script to clean up Jenkins data and containers

### Configuration
- **`docker-compose.yml`** - Docker Compose configuration for Jenkins
- **`Dockerfile`** - Custom Jenkins image with Podman and Maven
- **`containers.conf`** - Podman container configuration
- **`storage.conf`** - Podman storage configuration  
- **`registries.conf`** - Container registry configuration

## 🔧 What Gets Automated

### Directory Structure
```
jenkins_home/
├── .m2/
│   ├── repository/          # Maven local repository
│   ├── wrapper/             # Maven wrapper
│   └── settings.xml         # Maven configuration
└── [other Jenkins files]    # Created by Jenkins on first run
```

### Permissions
- Jenkins home directory: `777` (during setup) → `755` (after setup)
- Container user: `1000:1000` (jenkins user)
- Maven directories: Properly owned by Jenkins user

### Features Configured
- ✅ Jenkins with JDK 21
- ✅ Podman integration for container building
- ✅ Maven with proper repository configuration
- ✅ Host-based building to avoid VFS storage issues
- ✅ Registry resolution for Docker Hub

## 🛠️ Manual Commands

### View Jenkins logs
```bash
docker-compose logs jenkins -f
```

### Stop Jenkins
```bash
docker-compose down
```

### Restart Jenkins
```bash
docker-compose restart jenkins
```

### Access Jenkins shell
```bash
docker-compose exec jenkins bash
```

### Test Maven configuration
```bash
docker-compose exec jenkins mvn -Duser.home=/var/jenkins_home -Dmaven.repo.local=/var/jenkins_home/.m2/repository -s /var/jenkins_home/.m2/settings.xml --version
```

### Test Podman
```bash
docker-compose exec jenkins podman --version
```

## 🔍 Troubleshooting

### Jenkins won't start
1. Run cleanup: `./cleanup-jenkins.sh`
2. Check logs: `docker-compose logs jenkins`
3. Restart: `./start-jenkins.sh`

### Permission issues
The automation handles permissions automatically, but if you encounter issues:
```bash
sudo chown -R 1000:1000 jenkins_home
chmod 755 jenkins_home
```

### Maven issues
Check Maven configuration:
```bash
docker-compose exec jenkins cat /var/jenkins_home/.m2/settings.xml
```

### Podman issues
Verify Podman is working inside container:
```bash
docker-compose exec jenkins podman info
```

## 📋 Script Options

### start-jenkins.sh
```bash
./start-jenkins.sh --help      # Show help
./start-jenkins.sh --validate  # Run validation after setup
```

### cleanup-jenkins.sh  
```bash
./cleanup-jenkins.sh          # Basic cleanup
./cleanup-jenkins.sh --deep   # Deep cleanup including Docker resources
```

## 🌐 Access Points

- **Jenkins UI**: http://localhost:8080
- **Jenkins Agent**: http://localhost:50000

## 🔒 Security Notes

- Jenkins runs as user `1000:1000` inside container
- Host volume mount provides data persistence
- Podman runs in rootless mode for better security
- Maven repository is isolated to Jenkins home directory

## 🎯 Benefits

1. **Zero Configuration**: Just run `./start-jenkins.sh` 
2. **Repeatable**: Can delete `jenkins_home` and restart cleanly
3. **Proper Permissions**: Handles macOS/Linux permission mapping
4. **Maven Ready**: Pre-configured Maven with proper repository
5. **Podman Ready**: Host-based building avoids storage issues
6. **Registry Ready**: Pre-configured for Docker Hub access

## ⚠️ Known Issues and Solutions

### Maven Wrapper Permission Issues on macOS

Due to volume mount behavior on macOS with Podman, the Maven wrapper may encounter permission issues when trying to download dependencies to `/var/jenkins_home/.m2/wrapper/dists`.

**Symptoms:**
- `AccessDeniedException` when running `./mvnw` commands
- Permission denied errors for wrapper directory access

**Solutions:**
1. **Easy Pipeline Fix** (✅ **Recommended**):
   Add this stage to your pipeline before using `./mvnw`:
   ```groovy
   stage('Fix Maven Wrapper') {
       steps {
           sh '''
               cat > mvnw << 'EOF'
#!/bin/bash
exec /tmp/maven-interceptor/mvnw "$@"
EOF
               chmod +x mvnw
           '''
       }
   }
   ```
   Then use `./mvnw` normally in subsequent stages.

2. **Use system Maven directly** (Alternative):
   ```groovy
   sh 'mvn clean package'
   ```
   ```bash
   # Run on host before Jenkins pipeline
   podman exec jenkins mvn wrapper:wrapper
   ```

### Registry Resolution Issues

If you encounter errors like "image not found" or registry connection issues:

**Solution:**
- Always use fully qualified image names in pipelines:
  ```groovy
  sh 'podman build -t docker.io/library/myapp:latest .'
  ```

### VFS Storage Driver Limitations

Podman uses VFS storage driver in container mode, which can be slow for large images.

**Solution:**
- The setup uses host-based building strategy to mitigate this
- Commands run `podman` on host rather than inside container

## 💡 Best Practices

1. **Maven wrapper now works automatically** - no changes needed to existing `./mvnw` commands
2. **Always use fully qualified image names** in Podman commands
3. **Regular cleanup** during development with provided scripts
4. **Monitor disk usage** as VFS storage can accumulate data
5. **Use the automation scripts** for consistent environment setup