FROM python:latest

WORKDIR /app

COPY . .

ENV DEBIAN_FRONTEND=noninteractive

RUN chmod +x installer.sh

RUN ./installer.sh

RUN tofu init

RUN pip install --no-cache-dir -r requirements.txt

ENTRYPOINT ["python", "/app/app.py"]