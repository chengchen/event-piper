import Config

config :event_piper,
       ecto_repos: [EventPiper.Repo]

config :event_piper, EventPiper.Repo,
       url: "ecto://event_piper:event_piper@postgresql/event_piper",
       auto_reconnect: true
