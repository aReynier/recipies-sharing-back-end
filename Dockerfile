FROM node:20-alpine AS base

ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
RUN corepack enable

WORKDIR /src/app

COPY . .

FROM base AS prod-deps
RUN --mount=type=cache,id=pnpm,target=/pnpm/store pnpm install --prod --frozen-lockfile

FROM base AS build
RUN --mount=type=cache,id=pnpm,target=/pnpm/store pnpm install --frozen-lockfile
RUN pnpm run build

FROM node:20-alpine

WORKDIR /app

# Copy production dependencies and build output
COPY --from=prod-deps /src/app/node_modules ./node_modules
COPY --from=build /src/app/dist ./dist
COPY --from=build /src/app/package.json ./package.json

# Set environment variables
ENV HOST=0.0.0.0
ENV PORT=3000

EXPOSE 3000

# Add healthcheck
HEALTHCHECK --interval=30s --timeout=3s \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3000/health || exit 1

CMD ["node", "dist/main"]