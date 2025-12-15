# SonarQube Docker Compose Setup

A production-ready SonarQube environment with PostgreSQL database using Docker Compose, suitable for both development and server deployment.

## Features

- ✅ SonarQube Community Edition 25.12.0
- ✅ PostgreSQL 17.2 (Alpine)
- ✅ Persistent data volumes
- ✅ Health checks and automatic restarts
- ✅ Isolated Docker network
- ✅ Optional Telegram/Slack notifications

## Prerequisites

- Docker Engine 20.10+
- Docker Compose 2.0+
- At least 2GB of available RAM
- At least 5GB of available disk space

## Quick Start

### 1. Clone or Navigate to Directory

```bash
cd /path/to/docker-scripts/sonar
```

### 2. Configure Environment Variables

```bash
# Copy the example environment file
cp .env.example .env

# Edit the .env file with your preferred editor
nano .env
```

**Required Configuration:**
- `POSTGRES_PASSWORD`: Change from default to a secure password

**Optional Configuration:**
- `TELEGRAM_BOT_TOKEN` and `TELEGRAM_CHAT_ID`: For Telegram notifications
- `SLACK_WEBHOOK_URL`: For Slack notifications

### 3. Start Services

```bash
# Start in detached mode
docker-compose up -d

# View logs
docker-compose logs -f
```

### 4. Access SonarQube

- **URL**: http://localhost:9000
- **Default credentials**: 
  - Username: `admin`
  - Password: `admin`
- **Important**: You'll be prompted to change the password on first login

## Usage

### Start Services

```bash
docker-compose up -d
```

### Stop Services

```bash
docker-compose down
```

### Stop Services and Remove Volumes (⚠️ Data Loss)

```bash
docker-compose down -v
```

### View Logs

```bash
# All services
docker-compose logs -f

# SonarQube only
docker-compose logs -f sonarqube

# PostgreSQL only
docker-compose logs -f postgres
```

### Restart Services

```bash
docker-compose restart
```

### Check Service Status

```bash
docker-compose ps
```

## Data Persistence

All data is persisted in Docker volumes:

- `postgres_data`: PostgreSQL database files
- `sonarqube_data`: SonarQube data files
- `sonarqube_extensions`: SonarQube plugins and extensions
- `sonarqube_logs`: SonarQube logs

To backup your data:

```bash
# Backup PostgreSQL
docker-compose exec postgres pg_dump -U sonarqube sonarqube > backup.sql

# Backup volumes
docker run --rm -v sonar_postgres_data:/data -v $(pwd):/backup alpine tar czf /backup/postgres_backup.tar.gz /data
```

## System Requirements

SonarQube requires specific system settings:

### Linux (Required)

```bash
# Increase virtual memory
sudo sysctl -w vm.max_map_count=262144

# Make it permanent
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
```

### macOS

Docker Desktop for Mac automatically handles these settings.

## Optional: Notification Integrations

### Telegram Notifications

1. **Create a Telegram Bot**:
   - Message [@BotFather](https://t.me/BotFather) on Telegram
   - Send `/newbot` and follow instructions
   - Save the bot token

2. **Get Your Chat ID**:
   - Message your bot
   - Visit: `https://api.telegram.org/bot<YourBOTToken>/getUpdates`
   - Find your chat ID in the response

3. **Configure SonarQube Webhook**:
   - Go to SonarQube → Administration → Configuration → Webhooks
   - Create a new webhook pointing to your webhook handler
   - See `integrations/telegram-webhook.sh` for a sample handler

### Slack Notifications

1. **Create a Slack Incoming Webhook**:
   - Go to your Slack workspace settings
   - Navigate to Apps → Incoming Webhooks
   - Add New Webhook to Workspace
   - Copy the webhook URL

2. **Configure SonarQube Webhook**:
   - Go to SonarQube → Administration → Configuration → Webhooks
   - Create a new webhook pointing to your webhook handler
   - See `integrations/slack-webhook.sh` for a sample handler

### Webhook Handler Deployment

The webhook handler scripts in the `integrations/` directory can be deployed as:
- A simple Node.js/Python web service
- An AWS Lambda function
- A Google Cloud Function
- Any HTTP endpoint that can receive POST requests

## Troubleshooting

### SonarQube Won't Start

**Issue**: Container exits immediately

**Solution**:
```bash
# Check logs
docker-compose logs sonarqube

# Common causes:
# 1. Insufficient memory - increase Docker memory limit
# 2. vm.max_map_count too low (Linux) - see System Requirements
# 3. Port 9000 already in use - change port in docker-compose.yml
```

### Database Connection Error

**Issue**: SonarQube can't connect to PostgreSQL

**Solution**:
```bash
# Check PostgreSQL is healthy
docker-compose ps

# Verify database credentials in .env file
# Restart services
docker-compose restart
```

### Port Already in Use

**Issue**: Port 9000 is already allocated

**Solution**:
Edit `docker-compose.yml` and change the port mapping:
```yaml
ports:
  - "9001:9000"  # Use port 9001 instead
```

### Slow Performance

**Issue**: SonarQube is slow or unresponsive

**Solution**:
- Increase Docker memory allocation (minimum 2GB, recommended 4GB)
- Check available disk space
- Review SonarQube logs for errors

### Reset Admin Password

**Issue**: Forgot admin password

**Solution**:
```bash
# Connect to PostgreSQL
docker-compose exec postgres psql -U sonarqube -d sonarqube

# Reset password to 'admin'
UPDATE users SET crypted_password='$2a$12$uCkkXmhW5ThVK8mpBvnXOOJRLd64LJeHTeCkSuB3lfaR2N0AYBaSi', salt=null, hash_method='BCRYPT' WHERE login='admin';

# Exit psql
\q
```

## Upgrading SonarQube

1. **Backup your data** (see Data Persistence section)
2. Update the image version in `docker-compose.yml`
3. Pull the new image:
   ```bash
   docker-compose pull
   ```
4. Restart services:
   ```bash
   docker-compose down
   docker-compose up -d
   ```

## Security Recommendations

- ✅ Change default admin password immediately
- ✅ Use strong PostgreSQL password in `.env`
- ✅ Keep `.env` file out of version control (already in `.gitignore`)
- ✅ Regularly update SonarQube and PostgreSQL images
- ✅ Use HTTPS in production (configure reverse proxy)
- ✅ Restrict network access to port 9000
- ✅ Regular backups of volumes

## Network Architecture

```
┌─────────────────────────────────────┐
│     sonarqube-network (bridge)      │
│                                     │
│  ┌──────────────┐  ┌─────────────┐ │
│  │  PostgreSQL  │  │  SonarQube  │ │
│  │   :5432      │◄─┤   :9000     │ │
│  └──────────────┘  └─────────────┘ │
│                           │         │
└───────────────────────────┼─────────┘
                            │
                    Host Port 9000
```

## Resources

- [SonarQube Documentation](https://docs.sonarqube.org/latest/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)

## License

This configuration is provided as-is for use with SonarQube Community Edition.
