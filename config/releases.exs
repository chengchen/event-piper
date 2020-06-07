import Config

config :event_piper, EventPiper.Repo,
       url: "ecto://event_piper:event_piper@postgresql/event_piper"
