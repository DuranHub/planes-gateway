# Base image with Node.js and system dependencies
FROM node:20.12.2 as base

ARG ENGINE_URL

ENV ENGINE_URL=${ENGINE_URL} NODE_ENV=production PORT=3001

RUN apt-get update && apt-get install -y openssl

WORKDIR /myapp

# Stage for installing development dependencies
FROM base as dev-dependencies

WORKDIR /myapp
COPY package.json yarn.lock ./
RUN yarn install --production=false

# Stage for installing production dependencies
FROM dev-dependencies as prod-dependencies

RUN yarn install --production=true

# Stage for building the application
FROM base as build

WORKDIR /myapp
COPY --from=dev-dependencies /myapp/node_modules /myapp/node_modules
COPY . .

# Final stage: production image with minimal footprint
FROM base

WORKDIR /myapp
COPY --from=prod-dependencies /myapp/node_modules /myapp/node_modules
COPY --from=build /myapp /myapp

RUN ENGINE_URL=$ENGINE_URL yarn build

CMD ["yarn", "dev"]