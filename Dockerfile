FROM elixir:1.8-alpine
COPY . .
ENV MIX_ENV=prod
RUN mix local.hex --force
# get dependencies
RUN mix deps.get
RUN mix local.rebar --force
# compile app
RUN mix compile
# run application
CMD ["mix", "run", "--no-halt"]