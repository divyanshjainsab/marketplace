FROM ruby:3.3.11-slim

WORKDIR /app

ENV BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_JOBS=4 \
    BUNDLE_RETRY=3

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential libpq-dev libyaml-dev pkg-config postgresql-client && \
    rm -rf /var/lib/apt/lists/*

COPY backend/Gemfile ./Gemfile
RUN bundle install

COPY backend/ .
COPY docker/rails/entrypoint.sh /usr/local/bin/rails-entrypoint
RUN chmod +x /usr/local/bin/rails-entrypoint

EXPOSE 3000

ENTRYPOINT ["rails-entrypoint"]
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0", "-p", "3000"]
