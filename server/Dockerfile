FROM elixir:1.11-slim

RUN mix local.hex --force \
    && mix local.rebar --force

ENV APP_HOME /app

WORKDIR $APP_HOME

EXPOSE 4000

COPY mix.exs mix.lock .
COPY bitcoinex ./bitcoinex

RUN mix do deps.get
RUN mix do deps.compile

COPY lib ./lib
COPY log ./log

ENV MIX_ENV prod
ENV RELEASE_NODE bitfeed
RUN mix release
RUN mkdir /app/data
RUN chown -R 1000:1000 /app/
RUN chmod -R 755 /app/

CMD ["/app/_build/prod/rel/prod/bin/prod", "start"]
