FROM node:lts-alpine AS deps
RUN apk add --no-cache libc6-compat
WORKDIR /app
COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile


RUN mkdir -p /app/node_modules/.cache && chmod -R 777 /app/node_modules/.cache

FROM node:lts-alpine AS builder
RUN apk add --no-cache curl
WORKDIR /app

RUN addgroup -g 1001 -S nodejs
RUN adduser -S nextjs -u 1001
COPY --chown=nextjs:nodejs . .
COPY --from=deps /app/node_modules ./node_modules

RUN mkdir -p /app/.next /app/public /app/public/static
RUN chown -R nextjs:nodejs /app/.next /app/public /app/public/static
RUN chmod -R 777 /app/.next /app/public /app/public/static


ENV PORT=3001

USER nextjs

EXPOSE 3001

ENV NODE_ENV production
ENV NEXT_TELEMETRY_DISABLED 1

HEALTHCHECK --interval=1m --timeout=3s CMD curl -f http://localhost:3001/ || exit 1

CMD NEXT_PUBLIC_SITE_DOMAIN=$site_domain\
    NEXT_PUBLIC_FORCE_DEFAULT_THEME=$force_default_theme \
    NEXT_PUBLIC_DEFAULT_SOURCE_LANG=$default_source_lang \
    NEXT_PUBLIC_DEFAULT_TARGET_LANG=$default_target_lang \
    yarn build && yarn start
