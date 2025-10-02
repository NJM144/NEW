# ---- build front
FROM node:18-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
# Neutralize API base at build; we proxy /api from Nginx so front will call same-origin
ARG VITE_AGRO_API=
ENV VITE_AGRO_API=$VITE_AGRO_API
RUN npm run build

# ---- nginx runtime
FROM nginx:alpine
# Copy nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf
# Copy built assets
COPY --from=build /app/dist /usr/share/nginx/html
# Railway injects $PORT; default to 8080 locally
ENV PORT=8080
EXPOSE 8080
# Replace placeholder with $PORT and start nginx
CMD sh -c "sed -i \"s/PORT_PLACEHOLDER/${PORT}/g\" /etc/nginx/conf.d/default.conf && nginx -g 'daemon off;'"
