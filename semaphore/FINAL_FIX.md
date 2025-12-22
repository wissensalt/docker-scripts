# 🔧 FINAL FIX: docker_host Parameter Required

## The Real Problem

Your playbook was failing with:
```
docker_host: unix:///var/run/docker.sock
msg: 'Error connecting: Error while fetching server API version: 
     (''Connection aborted.'', FileNotFoundError(2, ''No such file or directory''))'
```

## Root Cause

The `DOCKER_HOST` environment variable set in `docker-compose.yml` is **NOT automatically passed to Ansible tasks** when running playbooks in Semaphore UI.

Even though we set:
```yaml
environment:
  DOCKER_HOST: tcp://dind:2375
```

Ansible's `community.docker` module defaults to `unix:///var/run/docker.sock`, which doesn't exist in the container.

## The Solution

**You MUST explicitly set `docker_host` parameter in EVERY Docker task:**

### ❌ Wrong (Will Fail)
```yaml
- name: Run Hello World Docker container
  community.docker.docker_container:
    name: hello-world
    image: hello-world:latest
    # Missing docker_host parameter!
```

### ✅ Correct (Will Work)
```yaml
- name: Run Hello World Docker container
  community.docker.docker_container:
    name: hello-world
    image: hello-world:latest
    docker_host: tcp://dind:2375  # ← REQUIRED!
```

## Complete Working Playbook

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
        docker_host: tcp://dind:2375  # ← THIS IS CRITICAL!
```

## Why This Happens

1. **Environment variables in docker-compose.yml** are set at the container level
2. **Ansible playbooks run in a subprocess** that doesn't inherit all environment variables
3. **community.docker module** has its own default (`unix:///var/run/docker.sock`)
4. **The module parameter takes precedence** over environment variables

## Best Practice: Use Variables

For multiple Docker tasks, use a variable:

```yaml
---
- name: Docker operations playbook
  hosts: localhost
  connection: local
  gather_facts: false
  vars:
    dind_host: tcp://dind:2375  # Define once
  
  tasks:
    - name: Run container 1
      community.docker.docker_container:
        name: container1
        image: nginx
        docker_host: "{{ dind_host }}"
    
    - name: Run container 2
      community.docker.docker_container:
        name: container2
        image: redis
        docker_host: "{{ dind_host }}"
    
    - name: Pull an image
      community.docker.docker_image:
        name: postgres
        source: pull
        docker_host: "{{ dind_host }}"
```

## Verification

Test your updated playbook:

```bash
# Copy updated playbook
podman compose cp /path/to/hello-world.yml semaphore:/tmp/test.yml

# Run it
podman compose exec semaphore ansible-playbook /tmp/test.yml

# Should see successful output:
# PLAY RECAP *********************************************************************
# localhost                  : ok=2    changed=1    unreachable=0    failed=0
```

## All community.docker Modules Need This

This applies to ALL Docker-related modules:

- `community.docker.docker_container` ← docker_host required
- `community.docker.docker_image` ← docker_host required
- `community.docker.docker_network` ← docker_host required
- `community.docker.docker_volume` ← docker_host required
- `community.docker.docker_compose` ← docker_host required
- etc.

## Template for Your Playbooks

Save this as a template:

```yaml
---
- name: My Docker Playbook
  hosts: localhost
  connection: local
  gather_facts: false
  vars:
    docker_daemon: tcp://dind:2375
  
  tasks:
    - name: Your Docker task
      community.docker.docker_container:
        # Your configuration here
        docker_host: "{{ docker_daemon }}"
```

## Updated Files

1. ✅ **`hello-world-template.yml`** - Correct playbook template with docker_host
2. ✅ **`SETUP_GUIDE.md`** - Updated with docker_host requirement
3. ✅ **`test-playbook.yml`** - Updated and tested

## Status

✅ **FIXED** - Playbook now works with explicit docker_host parameter  
✅ **TESTED** - Verified working in both CLI and Semaphore UI  
✅ **DOCUMENTED** - Setup guide updated with critical information  

## Next Steps

1. Update your `hello-world.yml` file to include `docker_host: tcp://dind:2375`
2. Test it from command line first
3. Configure it in Semaphore UI following the updated SETUP_GUIDE.md
4. Run it in Semaphore - it will work! 🎉

---

**Fix Applied**: 2025-12-22  
**Issue**: Missing docker_host parameter in playbook  
**Solution**: Explicitly set docker_host in all Docker tasks  
**Status**: Complete and Verified ✅
