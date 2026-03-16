FROM nginx:1.27-alpine

ARG VERSION=v1

COPY index.html /usr/share/nginx/html/index.html
COPY styles.css /usr/share/nginx/html/styles.css
COPY app.js /usr/share/nginx/html/app.js

# Inject version at build time
RUN sed -i "s/__APP_VERSION__/${VERSION}/g" /usr/share/nginx/html/app.js
