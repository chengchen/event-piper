FROM elixir:1.10.3-slim

WORKDIR /usr/src

COPY config config
COPY lib lib
COPY mix.exs .
COPY mix.lock .

RUN mix local.hex --force \
    && mix local.rebar --force \
    && mix deps.get \
    && mix compile

CMD ["mix", "run", "--no-halt"]
