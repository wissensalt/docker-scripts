# Use the same base image as in docker-compose.yml
FROM nginx:stable-alpine3.23-perl

# Copy custom nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Copy custom index.html page
COPY index.html /usr/share/nginx/html/index.html

# Expose the ports that nginx will listen on
EXPOSE 80 443

# Start nginx (this is the default command, but included for clarity)
CMD ["nginx", "-g", "daemon off;"]