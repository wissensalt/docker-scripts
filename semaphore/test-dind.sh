#!/bin/bash
# Test script to verify Docker-in-Docker setup with Ansible

echo "=== Testing Docker-in-Docker Setup ==="
echo ""

echo "1. Checking Docker connectivity..."
podman compose exec semaphore docker ps
if [ $? -eq 0 ]; then
    echo "✅ Docker daemon is accessible"
else
    echo "❌ Cannot connect to Docker daemon"
    exit 1
fi
echo ""

echo "2. Checking Docker Python SDK..."
podman compose exec semaphore python3 -c "import docker; print(f'Docker SDK version: {docker.__version__}')"
if [ $? -eq 0 ]; then
    echo "✅ Docker Python SDK is installed"
else
    echo "❌ Docker Python SDK not found"
    exit 1
fi
echo ""

echo "3. Checking Ansible Docker collection..."
podman compose exec semaphore ansible-galaxy collection list | grep community.docker
if [ $? -eq 0 ]; then
    echo "✅ Ansible Docker collection is installed"
else
    echo "❌ Ansible Docker collection not found"
    exit 1
fi
echo ""

echo "4. Testing Docker container execution..."
podman compose exec semaphore docker run --rm hello-world
if [ $? -eq 0 ]; then
    echo "✅ Successfully ran hello-world container"
else
    echo "❌ Failed to run hello-world container"
    exit 1
fi
echo ""

echo "=== All tests passed! ==="
echo ""
echo "Your setup is ready to run Ansible playbooks with Docker containers."
echo "You can now configure Semaphore with your hello-world.yml playbook."


