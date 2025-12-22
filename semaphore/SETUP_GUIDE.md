# Setting Up Your Hello World Playbook in Semaphore

## ⚠️ CRITICAL: Update Your Playbook First!

Before configuring Semaphore, you **MUST** add the `docker_host` parameter to your playbook. The `DOCKER_HOST` environment variable is NOT automatically passed to Ansible tasks.

### Update Your hello-world.yml

Add `docker_host: tcp://dind:2375` to your docker_container task:

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
        state: started
        detach: false
        cleanup: true
        docker_host: tcp://dind:2375  # ← REQUIRED!
```

**Why is this needed?** When running in Semaphore UI, the playbook defaults to `unix:///var/run/docker.sock` which doesn't exist in the container. You must explicitly tell it to use the DinD daemon at `tcp://dind:2375`.

## Prerequisites
✅ Docker-in-Docker setup is complete and tested  
✅ Semaphore is running at http://localhost:3000  
✅ Your hello-world.yml playbook has `docker_host: tcp://dind:2375` parameter  

## Step-by-Step Configuration

### 1. Access Semaphore UI
- Open: http://localhost:3000
- Login with:
  - Username: `wissensalt`
  - Password: `Password123!`

### 2. Create a Project
1. Click **"New Project"**
2. Enter project name (e.g., "Docker Test")
3. Click **"Create"**

### 3. Add a Key Store (for Git Access)
1. Go to **"Key Store"** tab
2. Click **"New Key"**
3. Choose type:
   - **None** - if using local files
   - **SSH** - if using Git over SSH
   - **Login with password** - if using HTTPS Git
4. Enter key details and save

### 4. Create a Repository
1. Go to **"Repositories"** tab
2. Click **"New Repository"**
3. Configure:
   - **Name**: `hello-world-playbook`
   - **URL**: Your Git repository URL
   - **Branch**: `main` (or your branch name)
   - **Access Key**: Select the key from step 3
4. Click **"Save"**

### 5. Create an Inventory
1. Go to **"Inventory"** tab
2. Click **"New Inventory"**
3. Configure:
   - **Name**: `localhost`
   - **Type**: `Static`
   - **Inventory Content**: 
     ```ini
     localhost ansible_connection=local
     ```
4. Click **"Create"**

### 6. Create a Task Template
1. Go to **"Task Templates"** tab
2. Click **"New Template"**
3. Configure:
   - **Name**: `Run Hello World Docker`
   - **Playbook Filename**: `hello-world.yml`
   - **Inventory**: Select `localhost`
   - **Repository**: Select `hello-world-playbook`
   - **Environment**: Leave empty (or create one if you need env vars)
   - **Extra CLI Arguments** (optional): `-vvv` for verbose output
4. Click **"Create"**

### 7. Run the Task
1. Go to **"Tasks"** tab (or click "Run" from Task Templates)
2. Click **"New Task"** or **"Run"**
3. Select the template: `Run Hello World Docker`
4. Click **"Run"**
5. Watch the output in real-time!

## Expected Output

You should see:
```
PLAY [Basic playbook to say hello] *********************************************

TASK [Print a message] *********************************************************
ok: [localhost] => 
    msg: Hello, World! Updated

TASK [Run Hello World Docker container] ****************************************
changed: [localhost]

PLAY RECAP *********************************************************************
localhost                  : ok=2    changed=1    unreachable=0    failed=0
```

## Troubleshooting

### Error: "Error connecting: Error while fetching server API version"

**Root Cause**: Your playbook is missing the `docker_host` parameter.

**Solution**: Add `docker_host: tcp://dind:2375` to your `community.docker.docker_container` task (see example above).

### Error: "Cannot connect to Docker daemon"

**Solution**: Ensure DinD service is running:
```bash
podman compose ps dind
podman compose logs dind
```

### Error: "community.docker module not found"

**Solution**: Rebuild Semaphore container:
```bash
podman compose build --no-cache semaphore
podman compose up -d semaphore
```

### Error: "No such file or directory" when accessing docker.sock

**Solution**: This confirms you're missing the `docker_host` parameter. The playbook is trying to use the default Unix socket instead of the TCP connection to DinD.

## Alternative: Using Local Playbook File (No Git)

If you don't want to use Git:

### Option 1: Copy to Semaphore Volume
```bash
# Create a directory for playbooks
podman compose exec semaphore mkdir -p /tmp/playbooks

# Copy your playbook
podman compose cp /path/to/hello-world.yml semaphore:/tmp/playbooks/hello-world.yml
```

Then in Semaphore UI:
- Repository Type: **File**
- Path: `/tmp/playbooks`

### Option 2: Mount a Local Directory

Add to `docker-compose.yml` under semaphore service:
```yaml
volumes:
  - ./playbooks:/playbooks:ro
```

Then use `/playbooks` as your repository path.

## Testing from Command Line

Test your playbook before configuring Semaphore:

```bash
# Copy playbook to container
podman compose cp /path/to/hello-world.yml semaphore:/tmp/test.yml

# Run playbook
podman compose exec semaphore ansible-playbook /tmp/test.yml

# Should see successful output with both tasks completing
```

## Quick Reference: Required Playbook Format

Every Docker task in your playbooks **MUST** include `docker_host`:

```yaml
- name: Any Docker task
  community.docker.docker_container:
    # ... your container config ...
    docker_host: tcp://dind:2375  # Always required!
```

Or use a variable:

```yaml
- name: Basic playbook
  hosts: localhost
  vars:
    docker_host_url: tcp://dind:2375
  
  tasks:
    - name: Run container
      community.docker.docker_container:
        name: mycontainer
        image: myimage
        docker_host: "{{ docker_host_url }}"
```

## Quick Reference: Docker Compose

To use Docker Compose in your playbooks:

```yaml
- name: Deploy with Docker Compose
  ansible.builtin.command:
    cmd: docker compose -f /path/to/docker-compose.yml -p my_project up -d
  environment:
    DOCKER_HOST: tcp://dind:2375
```

See **DOCKER_COMPOSE_DEPLOY.md** for more details.

## Next Steps

Once your hello-world playbook works:
1. ✅ Add more complex Docker operations
2. ✅ Create multi-container deployments
3. ✅ Integrate with CI/CD pipelines
4. ✅ Add notifications and webhooks
5. ✅ Use Ansible variables for docker_host

Happy automating! 🚀

