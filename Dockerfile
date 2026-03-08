# Stage 1: Build
FROM node:18-alpine AS build
WORKDIR /usr/local/app
COPY ./ /usr/local/app/

# Accept build arguments for production URLs
ARG VITE_KEYCLOAK_URL
ARG VITE_KEYCLOAK_REALM
ARG VITE_KEYCLOAK_CLIENT_ID
ARG VITE_API_SERVER_URL
ARG VITE_APP_ENV=production

# Set environment variables for the build process
ENV VITE_KEYCLOAK_URL=$VITE_KEYCLOAK_URL
ENV VITE_KEYCLOAK_REALM=$VITE_KEYCLOAK_REALM
ENV VITE_KEYCLOAK_CLIENT_ID=$VITE_KEYCLOAK_CLIENT_ID
ENV VITE_API_SERVER_URL=$VITE_API_SERVER_URL
ENV VITE_APP_ENV=$VITE_APP_ENV

RUN npm install
RUN npm run build

# Stage 2: Serve
FROM nginx:alpine
WORKDIR /usr/share/nginx/html
COPY --from=build /usr/local/app/dist .
# Add nginx config for SPA routing
RUN rm /etc/nginx/conf.d/default.conf
COPY nginx.conf /etc/nginx/conf.d/default.conf
# Copy entrypoint script and config template for runtime config injection
COPY docker-entrypoint.sh /docker-entrypoint.sh
COPY public/config.template.js /usr/share/nginx/html/config.template.js
RUN chmod +x /docker-entrypoint.sh
# Install envsubst (provided by gettext package)
RUN apk add --no-cache gettext
EXPOSE 8881
ENTRYPOINT ["/docker-entrypoint.sh"]