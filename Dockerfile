# ---------- Build ----------
FROM node:22-bookworm-slim AS build
WORKDIR /app
ENV CI=true
RUN apt-get update && apt-get install -y --no-install-recommends python3 make g++ \
  && rm -rf /var/lib/apt/lists/*
COPY package*.json ./
RUN npm ci --include=dev
COPY . .
# Adaptez si besoin: vite/CRA/next export
RUN npm run build

# ---------- Runtime (nginx) ----------
FROM nginx:alpine
# Template lu par l’entrypoint nginx (envsubst)
COPY nginx.default.conf.template /etc/nginx/templates/default.conf.template
# Dossier de build front: changez 'dist' → 'build' ou 'out' si nécessaire
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]

