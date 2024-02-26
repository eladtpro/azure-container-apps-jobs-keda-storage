FROM python:latest

WORKDIR /app

COPY . .

ENV DEBIAN_FRONTEND=noninteractive

COPY installer.sh .

RUN chmod +x installer.sh

RUN ./installer.sh

ENTRYPOINT ["/app/app.py"]