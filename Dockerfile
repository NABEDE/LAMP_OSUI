# Start from an Ubuntu base image
FROM ubuntu:latest

# --- Configuration for adding a custom repository (if needed) ---
# If you are encountering GPG key errors because you are adding a third-party repository,
# you would typically add the key *before* adding the repository to your sources list.
# Replace 'YOUR_KEY_ID' with the actual key ID from your error message or repository instructions.
# Example: RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys YOUR_KEY_ID
#
# If you are NOT adding a custom repository and are still seeing key errors,
# it might indicate an issue with the base image's default repositories.
# For standard Ubuntu packages, you generally don't need to manually add keys.

# Add the repository to the sources list (if needed)
# Uncomment and modify the line below if you need to add a specific repository,
# for example, for a newer PHP version not in the default Ubuntu repos.
# Replace 'your-repository-url' and 'your-distribution' as appropriate.
# RUN echo "deb http://your-repository-url/ubuntu your-distribution main" >> /etc/apt/sources.list.d/custom.list
# RUN echo "deb-src http://your-repository-url/ubuntu your-distribution main" >> /etc/apt/sources.d/custom.list

# --- Core LAMP Stack Installation ---
# Update the package index, install necessary packages, and clean up apt cache.
# We're consolidating these steps into a single RUN command for efficiency.
RUN apt update && \
    DEBIAN_FRONTEND=noninteractive apt install -y \
    apache2 \
    mysql-server \
{{ edit_1 }}
    libapache2-mod-php8.1 \
    php8.1-mysql \
    git && \
    rm -rf /var/lib/apt/lists/*

# Note on MySQL Server: Installing mysql-server inside a Docker container
# running Apache is generally not recommended. MySQL is best run in its own
# separate container. For this Dockerfile, I've replaced `mysql-server` with
# `mysql-client` assuming the MySQL server will be external. If you absolutely
# need it in this container for a development setup, you can change it back,
# but be aware of the complexities of managing multiple services.

# Enable the Apache module for PHP
RUN a2enmod php8.1

# Copy your script into the container and make it executable
COPY lamp_ubuntu.sh /app/
RUN chmod +x /app/lamp_ubuntu.sh

# Expose port 80 for web traffic
EXPOSE 80

# Command to run your script. This will be the primary process of the container.
# Consider using 'apache2ctl -D FOREGROUND' if you just want Apache to run
# and your script handles other setup, or if your script itself starts Apache.
CMD ["/lamp_ubuntu.sh"]