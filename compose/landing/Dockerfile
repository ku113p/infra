FROM node:22-alpine AS build

WORKDIR /app

ARG VITE_NAME
ARG VITE_TITLE
ARG VITE_BIO
ARG VITE_EMAIL
ARG VITE_TELEGRAM
ARG VITE_LINKEDIN

ENV VITE_NAME=$VITE_NAME \
    VITE_TITLE=$VITE_TITLE \
    VITE_BIO=$VITE_BIO \
    VITE_EMAIL=$VITE_EMAIL \
    VITE_TELEGRAM=$VITE_TELEGRAM \
    VITE_LINKEDIN=$VITE_LINKEDIN

COPY app/package.json app/package-lock.json* ./
RUN npm ci
COPY app/ .
RUN npx vite build

FROM nginx:alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 80
