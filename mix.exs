defmodule EventPiper.MixProject do
  use Mix.Project

  def project do
    [
      app: :event_piper,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {EventPiper, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:plug_cowboy, "~> 2.2.1"},
      {:pubsub, "~> 1.0"},
      {:ecto_sql, "~> 3.4.3"},
      {:postgrex, "~> 0.15.3"},
      {:jason, "~> 1.2.0"}
    ]
  end
end
