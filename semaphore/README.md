# Semaphore with Docker-in-Docker (DinD) Setup

This setup allows Semaphore to run Ansible playbooks that execute Docker containers using the `community.docker` collection.

## Architecture

- **PostgreSQL**: Database for Semaphore
- **DinD (Docker-in-Docker)**: Isolated Docker daemon for running containers
- **Semaphore**: UI/orchestrator with Docker CLI and Ansible Docker collection pre-installed

## Key Features

✅ Docker-in-Docker for isolated container execution  
✅ Docker CLI and **Docker Compose V2** installed in Semaphore container  
✅ Ansible `community.docker` and `community.general` collections pre-installed  
✅ Shared network for service communication  
✅ Persistent storage for Docker images/containers  

## Quick Start

### 1. Build and Start Services

```bash
docker-compose up -d --build
```

### 2. Access Semaphore

- URL: http://localhost:3000
- Username: `wissensalt`
- Password: `Password123!`

### 3. Verify Docker Access

Check that Semaphore can communicate with DinD:

```bash
docker-compose exec semaphore docker ps
```

You should see an empty list (no containers running yet).

### 4. Test with Hello World Playbook

Your `hello-world.yml` playbook should now work:

```yaml
---
- name: Basic playbook to say hello
  hosts: localhost
  connection: local
  gather_facts: false

  tasks:
    - name: Print a message
      ansible.builtin.debug:
        msg: "Hello, World! Updated"
    - name: Run Hello World Docker container
      community.docker.docker_container:
        name: hello-world
        image: hello-world:latest
```

## Configuration Details

### DinD Service

- **Image**: `docker:29.1.3-dind`
- **Privileged**: Required for DinD to function
- **Docker Daemon**: Exposed on TCP port 2375 (no TLS)
- **Storage**: Persistent volume `dind-storage`

### Semaphore Service

- **Base Image**: `semaphoreui/semaphore:v2.16.47`
- **Custom Additions**:
  - Docker CLI (`docker-cli` package)
  - Docker Python SDK (`docker` v7.1.0) - **Required for Ansible Docker collection**
  - Ansible Docker collection (`community.docker` v4.1.0)
- **Docker Host**: `tcp://dind:2375`

## Troubleshooting

### Issue: "Cannot connect to Docker daemon"

**Solution**: Ensure DinD service is running:
```bash
docker-compose ps dind
docker-compose logs dind
```

### Issue: "community.docker collection not found"

**Solution**: Rebuild the Semaphore image:
```bash
docker-compose build --no-cache semaphore
docker-compose up -d semaphore
```

### Issue: "Permission denied while trying to connect to Docker daemon"

**Solution**: Verify DOCKER_HOST environment variable:
```bash
docker-compose exec semaphore env | grep DOCKER_HOST
# Should output: DOCKER_HOST=tcp://dind:2375
```

## Maintenance

### View Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f semaphore
docker-compose logs -f dind
```

### Restart Services

```bash
docker-compose restart
```

### Clean Up

```bash
# Stop and remove containers
docker-compose down

# Remove volumes (WARNING: deletes all data)
docker-compose down -v
```

## Security Notes

⚠️ **Important**: This setup uses Docker daemon without TLS for simplicity. For production:

1. Enable TLS on DinD daemon
2. Configure client certificates
3. Use secrets management for credentials
4. Restrict network access

## Network Architecture

```
┌─────────────┐
│  Semaphore  │
│  :3000      │
└──────┬──────┘
       │
       │ DOCKER_HOST=tcp://dind:2375
       │
       ▼
┌─────────────┐      ┌──────────────┐
│    DinD     │◄─────┤  PostgreSQL  │
│  :2375      │      │   :5432      │
└─────────────┘      └──────────────┘
       │
       │ semaphore-network
       │
```

## Environment Variables

| Variable | Value | Description |
|----------|-------|-------------|
| `DOCKER_HOST` | `tcp://dind:2375` | Docker daemon endpoint |
| `DOCKER_TLS_CERTDIR` | `""` | Disable TLS (dev only) |
| `SEMAPHORE_DB_HOST` | `postgres` | Database hostname |
| `SEMAPHORE_ADMIN` | `wissensalt` | Admin username |

## Next Steps

1. Configure your Ansible inventory in Semaphore
2. Add your playbook repository
3. Create a task template
4. Run your Docker-enabled playbooks! 🚀
