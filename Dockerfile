# Run tests and build release
FROM elixir:1.10.3-slim AS builder

WORKDIR /usr/src

COPY config config
COPY lib lib
COPY test test
COPY mix.exs .
COPY mix.lock .

RUN mix local.hex --force \
    && mix local.rebar --force \
    && mix deps.get \
    && mix test \
    && MIX_ENV=prod mix release

# Final release
FROM elixir:1.10.3-slim

WORKDIR /srv

COPY --from=builder /usr/src/_build/prod/rel .

CMD ["event_piper/bin/event_piper", "start"]
