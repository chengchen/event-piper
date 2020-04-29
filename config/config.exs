import Config

config :event_piper,
       ecto_repos: [EventPiper.Repo]

config :event_piper, EventPiper.Repo,
       url: "postgres://chengchen:chengchen@localhost/event_piper"
