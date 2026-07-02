FROM python:3.11-slim

WORKDIR /app

RUN apt-get update && apt-get install -y \
    curl \
    unzip \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install Lune
RUN curl -L https://github.com/lune-org/lune/releases/download/v0.10.4/lune-0.10.4-linux-x86_64.zip -o /tmp/lune.zip \
    && unzip /tmp/lune.zip -d /usr/local/bin \
    && chmod +x /usr/local/bin/lune \
    && ln -sf /usr/local/bin/lune /usr/bin/lune \
    && rm /tmp/lune.zip

# Verify installation
RUN lune --version

# Copy the entire project
COPY . .

# Make sure lune is in the project root (or symlink)
RUN ln -sf /usr/bin/lune /app/lune || true

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Create temp directory
RUN mkdir -p bot_tmp && chmod -R 777 bot_tmp

# Set environment variables
ENV HOOKOP_USE_LUNE=1
ENV HOOKOP_BIN=lune

EXPOSE 8080

CMD ["python", "bot.py"]
