defmodule EventPiper do

  @moduledoc """
  Documentation for `EventPiper`.
  """

  use Application

  @topic "new_events"

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    # List all child processes to be supervised
    children = [
      Plug.Cowboy.child_spec(
        scheme: :http,
        plug: EventPiper.ApiRouter,
        options: [port: 4000],
        protocol_options: [idle_timeout: :infinity]
      ),
      PubSub,
      EventPiper.Repo,
      EventPiper.EventListener
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: EventPiper.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def topic do
    @topic
  end

end
