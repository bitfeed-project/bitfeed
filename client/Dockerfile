FROM node:17-buster-slim as build

WORKDIR /app

COPY package.json .

RUN npm install

COPY babel.config.js .
COPY rollup.config.js .
COPY src ./src
COPY template ./template
COPY public ./public

RUN npm run build

FROM nginx:1.17.8@sha256:380eb808e2a3b0dd954f92c1cae2f845e6558a15037efefcabc5b4e03d666d03

EXPOSE 80

RUN apt-get update && apt-get install -y \
  gettext

COPY docker/docker-entrypoint.sh /
COPY docker/setup-env.sh /docker-entrypoint.d/05-setup-env.sh
COPY nginx/bitfeed.conf.template /etc/nginx/conf.d/default.conf.template
COPY nginx/bitfeed.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/public/build /var/www/bitfeed
RUN chmod 766 /var/www/bitfeed/env.js
RUN chmod 766 /etc/nginx/conf.d/default.conf

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["nginx", "-g", "daemon off;"]
