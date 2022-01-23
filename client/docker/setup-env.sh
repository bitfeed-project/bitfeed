#!/bin/sh
envsubst < "/var/www/bitfeed/env.template.js" > "/var/www/bitfeed/env.js"
envsubst '$BACKEND_HOST,$BACKEND_PORT' < "/etc/nginx/conf.d/default.conf.template" > "/etc/nginx/conf.d/default.conf"
