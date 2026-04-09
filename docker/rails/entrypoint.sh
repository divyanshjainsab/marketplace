#!/bin/sh
set -e

bundle check || bundle install
rm -f /app/tmp/pids/server.pid

if [ "$1" = "bundle" ] && [ "$2" = "exec" ] && [ "$3" = "rails" ]; then
  bundle exec rails db:prepare
fi

exec "$@"
