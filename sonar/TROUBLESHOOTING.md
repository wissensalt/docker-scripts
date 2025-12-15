# SonarQube Docker Setup - Issue Resolution

## Problem Summary

You encountered **Elasticsearch exit code 137** errors when starting SonarQube. This is an Out Of Memory (OOM) error where the system kills the Elasticsearch process.

## Root Causes

1. **Insufficient Memory**: Elasticsearch embedded in SonarQube requires significant memory (minimum 2GB recommended, 4GB for production)
2. **Permission Issues**: Bind-mounted directories had permission problems with the temp directory
3. **Bootstrap Checks**: Elasticsearch has strict bootstrap checks that can fail in development environments

## Fixes Applied

### 1. Increased Memory Limits (`docker-compose.yml`)

```yaml
mem_limit: 4g          # Maximum memory the container can use
mem_reservation: 2g    # Guaranteed minimum memory
shm_size: 512m         # Shared memory size
```

### 2. Added tmpfs for Temp Directory

```yaml
tmpfs:
  - /opt/sonarqube/temp:size=512M
```

This creates an in-memory filesystem for temporary files, avoiding permission issues and improving performance.

### 3. Disabled Elasticsearch Bootstrap Checks

```yaml
environment:
  SONAR_ES_BOOTSTRAP_CHECKS_DISABLE: "true"
```

This allows SonarQube to run in development/local environments without strict production requirements.

### 4. Removed Unused Volume Definitions

Since you're using bind mounts (`./sonarqube_data`), removed the named volumes section.

## Current Status

✅ **PostgreSQL**: Running and healthy  
✅ **Elasticsearch**: Starting successfully (no more exit code 137)  
⚠️ **Web Server**: Still initializing (this takes 2-3 minutes on first startup)

## Next Steps

### Wait for Full Startup

SonarQube takes time to start, especially on first run:
- Elasticsearch: ~30 seconds
- Database migration: ~60-90 seconds  
- Web Server: ~30-60 seconds

**Total first startup time: 2-4 minutes**

### Monitor Startup Progress

```bash
# Watch the logs
docker-compose logs -f sonarqube

# Check when it's ready (look for "SonarQube is operational")
docker-compose logs sonarqube | grep -i "operational\|started"

# Test web access
curl -I http://localhost:9000
```

### Verify It's Working

Once started, access:
- **URL**: http://localhost:9000
- **Username**: `admin`
- **Password**: `admin`

You'll be prompted to change the password on first login.

## Performance Optimization

If you experience slow startup or performance issues:

1. **Increase Docker Desktop Memory**:
   - Docker Desktop → Settings → Resources
   - Set memory to at least 6GB (8GB recommended)

2. **Check Available Disk Space**:
   ```bash
   df -h
   ```
   SonarQube needs at least 5-10GB free space

3. **Monitor Resource Usage**:
   ```bash
   docker stats sonarqube
   ```

## Troubleshooting Commands

```bash
# Check container status
docker-compose ps

# View all logs
docker-compose logs

# View specific service logs
docker-compose logs sonarqube
docker-compose logs postgres

# Check Elasticsearch logs
tail -f sonarqube_logs/es.log

# Check web server logs
tail -f sonarqube_logs/web.log

# Restart services
docker-compose restart

# Full restart (clean)
docker-compose down
docker-compose up -d
```

## What to Expect

### Successful Startup Sequence

1. **PostgreSQL starts** → becomes healthy (10 seconds)
2. **SonarQube container starts** → waits for PostgreSQL
3. **Elasticsearch starts** → initializes indices (30-60 seconds)
4. **Web Server starts** → connects to Elasticsearch and PostgreSQL
5. **Database migration runs** → creates/updates schema (60-90 seconds on first run)
6. **SonarQube becomes operational** → web interface available

### Log Messages to Look For

```
✅ "Process[es] is up" - Elasticsearch ready
✅ "Process[Web Server] is up" - Web server starting
✅ "SonarQube is operational" - Fully ready
```

## Final Configuration

Your `docker-compose.yml` now has:
- ✅ Proper memory limits (4GB max, 2GB reserved)
- ✅ tmpfs for temp directory
- ✅ Elasticsearch bootstrap checks disabled
- ✅ Health checks for PostgreSQL
- ✅ Proper service dependencies
- ✅ Bind mounts for data persistence

## Recommendation

**Be patient on first startup!** The initial database migration can take 2-4 minutes. Subsequent startups will be much faster (30-60 seconds).

If after 5 minutes it's still not accessible, check the logs for specific errors:

```bash
docker-compose logs sonarqube | grep -i "error\|exception" | tail -20
```
