# 🐳 Docker Compose Deployment Guide

## Overview

You can now use `docker compose` directly from your Ansible playbooks in Semaphore! This allows you to deploy multi-container applications easily.

## Requirements

1.  **Updated Dockerfile**: The Semaphore image now includes:
    *   `docker-cli-compose` (Modern Docker Compose V2)
    *   `community.docker` Ansible collection
    *   `community.general` Ansible collection

2.  **Explicit DOCKER_HOST**: Just like with regular containers, you must tell `docker compose` where the daemon is.

## Example Playbook

Save this as `deploy.yml`:

```yaml
---
- name: Deploy multi-container app
  hosts: localhost
  connection: local
  gather_facts: false
  vars:
    # Point to the DinD container
    docker_daemon: tcp://dind:2375
  
  tasks:
    - name: Ensure compose file exists
      ansible.builtin.copy:
        dest: /tmp/docker-compose.yml
        content: |
          services:
            web:
              image: nginx:alpine
              ports:
                - "8080:80"
            db:
              image: postgres:15-alpine
              environment:
                POSTGRES_PASSWORD: example_pass

    - name: Deploy with Docker Compose
      ansible.builtin.command:
        # Use 'docker compose' (version 2)
        cmd: docker compose -f /tmp/docker-compose.yml -p my_project up -d
      environment:
        # Pass the docker host via environment variable
        DOCKER_HOST: "{{ docker_daemon }}"
      register: deploy_result

    - name: Show output
      ansible.builtin.debug:
        var: deploy_result.stdout_lines
```

## Tips and Best Practices

### 1. Project Names
Always use the `-p` (project name) flag with `docker compose` to avoid naming conflicts if you run multiple deployments.

### 2. Cleaning Up
To stop and remove containers:
```yaml
- name: Stop deployment
  ansible.builtin.command:
    cmd: docker compose -f /tmp/docker-compose.yml -p my_project down
  environment:
    DOCKER_HOST: "{{ docker_daemon }}"
```

### 3. Verification
You can use `docker ps` to verify:
```yaml
- name: List containers
  ansible.builtin.shell:
    cmd: docker ps --format "{% raw %}table {{.Names}}\t{{.Status}}{% endraw %}"
  environment:
    DOCKER_HOST: "{{ docker_daemon }}"
  register: ps_out

- ansible.builtin.debug:
    var: ps_out.stdout_lines
```

## How to Test Now

I have created a test playbook for you at:
`/Users/achmadfauzi/Workspace/Wissensalt/docker-scripts/semaphore/docker-compose-deploy.yml`

You can test it from the host machine using:
```bash
cd /Users/achmadfauzi/Workspace/Wissensalt/docker-scripts/semaphore
podman compose cp docker-compose-deploy.yml semaphore:/tmp/deploy.yml
podman compose exec semaphore ansible-playbook /tmp/deploy.yml
```

---
**Status**: ✅ Docker Compose V2 Installed and Tested!
