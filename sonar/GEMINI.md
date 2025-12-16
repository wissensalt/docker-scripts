# SonarQube Docker Setup - Reference Documentation

## Repository Overview

This repository contains a production-ready Docker Compose setup for SonarQube Community Edition with PostgreSQL database, designed for both local development and server deployment.

**Location**: `/Users/achmadfauzi/Workspace/Wissensalt/docker-scripts/sonar`

## Purpose

- **Primary Goal**: Run SonarQube for code quality analysis in development and server environments
- **Use Cases**:
  - Local development code scanning
  - CI/CD integration for automated code quality checks
  - Team code quality monitoring
  - Technical debt tracking

## Architecture

### Components

```
┌─────────────────────────────────────────────────────┐
│              Docker Host (macOS)                    │
│                                                     │
│  ┌───────────────────────────────────────────────┐ │
│  │     sonarqube-network (bridge)                │ │
│  │                                               │ │
│  │  ┌──────────────────┐  ┌──────────────────┐  │ │
│  │  │   PostgreSQL     │  │    SonarQube     │  │ │
│  │  │   17.2-alpine    │  │  25.12.0-comm.   │  │ │
│  │  │                  │  │                  │  │ │
│  │  │  Port: 5432      │◄─┤  Port: 9000      │  │ │
│  │  │  (internal)      │  │  (exposed)       │  │ │
│  │  │                  │  │                  │  │ │
│  │  │  Health Check ✓  │  │  Depends On      │  │ │
│  │  └────────┬─────────┘  └──────┬────────┬──┘  │ │
│  │           │                   │        │     │ │
│  └───────────┼───────────────────┼────────┼─────┘ │
│              │                   │        │       │
│         ┌────▼────┐         ┌────▼────┐  │       │
│         │postgres_│         │sonarqube│  │       │
│         │  data   │         │ volumes │  │       │
│         └─────────┘         └─────────┘  │       │
│                                  │        │       │
│                             Port 9000  tmpfs      │
└──────────────────────────────────┼────────────────┘
                                   │
                          ┌────────▼─────────┐
                          │  User Browser    │
                          │ localhost:9000   │
                          └──────────────────┘
```

### Services

1. **PostgreSQL** (`postgres:17.2-alpine3.21`)
   - Database backend for SonarQube
   - Health checks enabled
   - Persistent storage via bind mount
   - Internal network only (not exposed to host)

2. **SonarQube** (`sonarqube:25.12.0.117093-community`)
   - Code quality analysis platform
   - Embedded Elasticsearch for indexing
   - Web interface on port 9000
   - Depends on PostgreSQL health check

3. **Network** (`sonarqube-network`)
   - Bridge network for service isolation
   - Allows inter-service communication

## File Structure

```
sonar/
├── docker-compose.yml          # Main orchestration file
├── .env.example                # Environment variables template
├── .gitignore                  # Git ignore rules
├── README.md                   # User documentation
├── TROUBLESHOOTING.md          # Issue resolution guide
├── integrations/               # Optional notification integrations
│   ├── README.md              # Integration documentation
│   ├── telegram-webhook.sh    # Telegram notification handler
│   └── slack-webhook.sh       # Slack notification handler
├── postgres_data/             # PostgreSQL data (bind mount)
├── sonarqube_data/            # SonarQube data (bind mount)
├── sonarqube_extensions/      # SonarQube plugins (bind mount)
└── sonarqube_logs/            # SonarQube logs (bind mount)
```

## Key Configuration Details

### Docker Compose Configuration

**File**: `docker-compose.yml`

#### PostgreSQL Service
- **Image**: `postgres:17.2-alpine3.21`
- **Container Name**: `sonarqube-postgres`
- **Environment Variables**:
  - `POSTGRES_USER`: Database user (default: sonarqube)
  - `POSTGRES_PASSWORD`: Database password (default: sonarqube)
  - `POSTGRES_DB`: Database name (default: sonarqube)
- **Volume**: `./postgres_data:/var/lib/postgresql/data` (bind mount)
- **Health Check**: `pg_isready -U sonarqube` every 10s
- **Restart Policy**: `unless-stopped`

#### SonarQube Service
- **Image**: `sonarqube:25.12.0.117093-community`
- **Container Name**: `sonarqube`
- **Dependencies**: Waits for PostgreSQL to be healthy
- **Environment Variables**:
  - `SONAR_JDBC_URL`: PostgreSQL connection string
  - `SONAR_JDBC_USERNAME`: Database username
  - `SONAR_JDBC_PASSWORD`: Database password
  - `SONAR_ES_BOOTSTRAP_CHECKS_DISABLE`: "true" (for dev environments)
- **Volumes** (bind mounts):
  - `./sonarqube_data:/opt/sonarqube/data`
  - `./sonarqube_extensions:/opt/sonarqube/extensions`
  - `./sonarqube_logs:/opt/sonarqube/logs`
- **tmpfs**: `/opt/sonarqube/temp:size=512M` (in-memory temp files)
- **Ports**: `9000:9000` (web interface)
- **Resource Limits**:
  - `mem_limit`: 4GB (maximum memory)
  - `mem_reservation`: 2GB (guaranteed memory)
  - `shm_size`: 512MB (shared memory)
- **ulimits**: `nofile` 65536 (file descriptors)
- **Restart Policy**: `unless-stopped`

### Environment Variables

**File**: `.env.example` (copy to `.env` for use)

```bash
# PostgreSQL Configuration
POSTGRES_USER=sonarqube
POSTGRES_PASSWORD=change_me_please  # ⚠️ Change this!
POSTGRES_DB=sonarqube

# Optional: Telegram Integration
TELEGRAM_BOT_TOKEN=your_telegram_bot_token_here
TELEGRAM_CHAT_ID=your_telegram_chat_id_here

# Optional: Slack Integration
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/YOUR/WEBHOOK/URL
```

## Important Technical Details

### Memory Requirements

**Critical**: SonarQube with embedded Elasticsearch requires significant memory:
- **Minimum**: 2GB RAM
- **Recommended**: 4GB RAM
- **Production**: 6-8GB RAM

**Docker Desktop Settings** (macOS):
- Must allocate at least 6GB to Docker Desktop
- Settings → Resources → Memory → 6GB or higher

### Startup Sequence

1. PostgreSQL starts (10 seconds)
2. PostgreSQL health check passes
3. SonarQube container starts
4. Elasticsearch initializes (30-60 seconds)
5. Web Server starts
6. Database migration runs (60-90 seconds on first run)
7. SonarQube becomes operational

**Total first startup time**: 2-4 minutes  
**Subsequent startups**: 30-60 seconds

### Data Persistence

All data is stored in bind-mounted directories (not Docker volumes):
- **postgres_data/**: PostgreSQL database files
- **sonarqube_data/**: SonarQube application data and Elasticsearch indices
- **sonarqube_extensions/**: Installed plugins and extensions
- **sonarqube_logs/**: Application logs (es.log, web.log, sonar.log, etc.)

**Advantages of bind mounts**:
- Easy to backup (just copy directories)
- Easy to inspect and debug
- Portable across Docker installations

### Known Issues & Solutions

#### Issue 1: Elasticsearch Exit Code 137 (OOM)
**Symptom**: Container restarts repeatedly, logs show "Elasticsearch exited with exit code 137"

**Cause**: Out of Memory - Elasticsearch is killed by the system

**Solution**:
1. Increase Docker Desktop memory allocation (6-8GB)
2. Memory limits already configured in docker-compose.yml
3. tmpfs for temp directory prevents permission issues

#### Issue 2: Permission Denied on Temp Directory
**Symptom**: "Unable to create directory /opt/sonarqube/temp"

**Cause**: Bind-mounted directories have permission issues

**Solution**: tmpfs mount for temp directory (already configured)

#### Issue 3: Slow Startup
**Symptom**: Takes 5+ minutes to start

**Cause**: Insufficient resources or first-time database migration

**Solution**:
- Ensure Docker Desktop has adequate memory
- First startup is always slower (database initialization)
- Check logs for actual errors vs. normal startup messages

## Common Operations

### Start Services
```bash
docker-compose up -d
```

### Stop Services
```bash
docker-compose down
```

### View Logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f sonarqube
docker-compose logs -f postgres
```

### Check Status
```bash
docker-compose ps
```

### Restart Services
```bash
docker-compose restart
```

### Access SonarQube
- **URL**: http://localhost:9000
- **Default Credentials**: admin / admin
- **First Login**: You'll be prompted to change the password

### Backup Data
```bash
# Backup PostgreSQL
docker-compose exec postgres pg_dump -U sonarqube sonarqube > backup.sql

# Backup all data directories
tar czf sonarqube-backup-$(date +%Y%m%d).tar.gz postgres_data/ sonarqube_data/ sonarqube_extensions/
```

## Optional Features

### Notification Integrations

Located in `integrations/` directory:

1. **Telegram Notifications** (`telegram-webhook.sh`)
   - Sends analysis results to Telegram
   - Requires bot token and chat ID
   - Node.js webhook server included

2. **Slack Notifications** (`slack-webhook.sh`)
   - Sends analysis results to Slack
   - Requires incoming webhook URL
   - Rich message formatting with color coding

**Setup**: See `integrations/README.md` for detailed instructions

## Security Considerations

1. **Change Default Password**: Immediately change admin password on first login
2. **Secure Database Password**: Update `POSTGRES_PASSWORD` in `.env`
3. **Keep .env Secret**: Already in `.gitignore`, never commit
4. **Regular Updates**: Update Docker images for security patches
5. **Network Access**: Consider using reverse proxy with HTTPS in production
6. **Firewall Rules**: Restrict access to port 9000 in production

## Monitoring & Debugging

### Log Files
- **es.log**: Elasticsearch logs
- **web.log**: Web server logs
- **sonar.log**: Main application logs
- **access.log**: HTTP access logs
- **deprecation.log**: Elasticsearch deprecation warnings

### Health Checks
```bash
# PostgreSQL health
docker-compose exec postgres pg_isready -U sonarqube

# SonarQube web interface
curl -I http://localhost:9000

# Container resource usage
docker stats sonarqube sonarqube-postgres
```

### Troubleshooting Commands
```bash
# Check for errors
docker-compose logs sonarqube | grep -i "error\|exception"

# Check Elasticsearch status
tail -f sonarqube_logs/es.log

# Verify database connection
docker-compose exec postgres psql -U sonarqube -d sonarqube -c '\l'
```

## Development Workflow

### Typical Usage Pattern

1. **Initial Setup**:
   ```bash
   cd /Users/achmadfauzi/Workspace/Wissensalt/docker-scripts/sonar
   cp .env.example .env
   # Edit .env with secure password
   docker-compose up -d
   ```

2. **Daily Use**:
   ```bash
   # Start
   docker-compose up -d
   
   # Analyze code (from project directory)
   sonar-scanner -Dsonar.host.url=http://localhost:9000
   
   # Stop
   docker-compose down
   ```

3. **Maintenance**:
   ```bash
   # Update images
   docker-compose pull
   docker-compose up -d
   
   # Backup
   tar czf backup-$(date +%Y%m%d).tar.gz postgres_data/ sonarqube_data/
   ```

## CI/CD Integration

SonarQube can be integrated with:
- Jenkins
- GitLab CI
- GitHub Actions
- Bitbucket Pipelines
- Azure DevOps

**Connection Details**:
- **Server URL**: http://localhost:9000 (or server IP)
- **Authentication**: Generate token in SonarQube UI
- **Project Key**: Configure in sonar-project.properties

## Version Information

- **SonarQube**: 25.12.0.117093-community
- **PostgreSQL**: 17.2-alpine3.21
- **Elasticsearch**: 8.16.6 (embedded in SonarQube)
- **Docker Compose**: v2.0+

## Future Enhancements

Potential improvements:
- [ ] Add nginx reverse proxy for HTTPS
- [ ] Implement automated backups
- [ ] Add monitoring with Prometheus/Grafana
- [ ] Create separate production configuration
- [ ] Add LDAP/Active Directory integration
- [ ] Implement quality gate webhooks
- [ ] Add more notification integrations (Discord, MS Teams)

## References

- [SonarQube Documentation](https://docs.sonarqube.org/latest/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [SonarQube Docker Image](https://hub.docker.com/_/sonarqube)

## Maintenance Notes

**Last Updated**: 2025-12-15

**Recent Changes**:
- Fixed Elasticsearch OOM issues with proper memory limits
- Added tmpfs for temp directory to resolve permission issues
- Disabled Elasticsearch bootstrap checks for development
- Switched from named volumes to bind mounts for easier management
- Added comprehensive documentation and troubleshooting guide

**Known Working Configuration**:
- macOS with Docker Desktop
- Docker Desktop Memory: 6GB+
- All services start successfully in 2-4 minutes
- Web interface accessible at http://localhost:9000
- Database persists across restarts

## Quick Reference

### Essential Commands
```bash
# Start
docker-compose up -d

# Stop
docker-compose down

# Logs
docker-compose logs -f sonarqube

# Status
docker-compose ps

# Access
open http://localhost:9000
```

### Default Credentials
- **Username**: admin
- **Password**: admin (change on first login)

### Ports
- **9000**: SonarQube web interface (exposed)
- **5432**: PostgreSQL (internal only)
- **9001**: Elasticsearch (internal only)

### Resource Requirements
- **CPU**: 2+ cores recommended
- **RAM**: 4GB minimum, 6-8GB recommended
- **Disk**: 10GB+ free space

---

**Note**: This setup is optimized for development and small team usage. For production deployments with high load, consider:
- External PostgreSQL database
- Load balancing
- High availability setup
- Regular automated backups
- Monitoring and alerting
- HTTPS with valid certificates
