# ---------- Build stage ----------
FROM node:22-bookworm-slim AS build
ENV NODE_ENV=production
WORKDIR /app

# Avoid interactive prompts
ENV CI=true
# Optional: faster, quieter npm
ENV npm_config_update_notifier=false

# Install minimal build tools for native deps (if any)
RUN apt-get update \
 && apt-get install -y --no-install-recommends python3 make g++ \
 && rm -rf /var/lib/apt/lists/*

# 1) Install deps from lockfile
COPY package*.json ./
RUN npm ci --include=dev

# 2) Build your app (Vite/Next/React/etc.)
COPY . .
# If your build script is "build", this works; otherwise adjust
RUN npm run build

# ---------- Runtime (nginx) ----------
FROM nginx:alpine AS runtime
# SPA routing + API proxy config
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy the static build output.
# - For Vite/React:   /app/dist
# - For Next.js:      /app/.next/static + a different nginx setup
# Change path below to match your project output folder.
COPY --from=build /app/dist /usr/share/nginx/html

# If you inject a runtime config file, place it here (optional).
# COPY --from=build /app/runtime-config.js /usr/share/nginx/html/

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]

