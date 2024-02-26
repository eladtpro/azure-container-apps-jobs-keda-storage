FROM debian:latest

# Set the working directory in the Docker image
WORKDIR /app

COPY . .

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && apt install -y PACKAGE && rm -rf /var/lib/apt/lists/*


# Make the script executable
RUN chmod +x installer.sh

ENTRYPOINT ["/app/installer.sh"]