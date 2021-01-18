FROM node:alpine AS dependencies

WORKDIR /usr/src/app

RUN chown -R node:node

USER node

COPY --chown=node:node package*.json ./

RUN npm i

COPY --chown=node:node ./ ./

ARG REACT_APP_BACKEND_WS

ARG REACT_APP_BACKEND_URL

RUN npm run build

FROM nginx:alpine

COPY config/nginx.conf /etc/nginx/nginx.conf

COPY --from=dependencies /usr/src/app/build/ /usr/share/nginx/html/