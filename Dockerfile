FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .

RUN apt-get update && apt-get install -y \
    wget \
    unzip \
    wine \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir -r requirements.txt

COPY . .

RUN chmod +x lune || true
RUN chmod +x lute || true
RUN chmod +x lute.exe || true

CMD ["python", "bot.py"]
