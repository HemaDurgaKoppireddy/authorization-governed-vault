FROM node:18-alpine

WORKDIR /app

# Copy dependency files first (Docker cache optimization)
COPY package.json package-lock.json ./

# Install dependencies
RUN npm install

# Copy full project
COPY . .

# Run deployment at container startup
CMD ["sh", "./docker/entrypoint.sh"]
