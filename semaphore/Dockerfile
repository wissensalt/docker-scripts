FROM semaphoreui/semaphore:v2.16.47

# Switch to root to install packages
USER root

# Install Docker CLI, Docker Compose, and Python dependencies
RUN apk add --no-cache docker-cli docker-cli-compose py3-pip

# Install Docker Python SDK (required by Ansible community.docker collection)
RUN pip3 install --no-cache-dir docker --break-system-packages

# Install Ansible Docker collection
RUN ansible-galaxy collection install community.docker community.general

# Verify installations
RUN docker --version && \
    docker compose version && \
    python3 -c "import docker; print(f'Docker SDK version: {docker.__version__}')" && \
    ansible-galaxy collection list | grep -E 'community\.(docker|general)'

# Switch back to the original user (if any)
USER semaphore

