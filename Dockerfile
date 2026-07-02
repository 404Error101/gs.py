FROM python:3.11-slim

WORKDIR /app

RUN apt-get update && apt-get install -y curl unzip && rm -rf /var/lib/apt/lists/*

RUN curl -L https://github.com/lune-org/lune/releases/download/v0.10.4/lune-0.10.4-linux-x86_64.zip -o /tmp/lune.zip \
    && unzip /tmp/lune.zip -d /usr/local/bin \
    && chmod +x /usr/local/bin/lune \
    && ln -s /usr/local/bin/lune /usr/bin/lune \
    && rm /tmp/lune.zip

COPY . .

RUN mkdir -p bot_tmp && chmod -R 777 bot_tmp

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

RUN chmod +x lute* 2>/dev/null || true

EXPOSE 8080

CMD ["python", "bot.py"]
