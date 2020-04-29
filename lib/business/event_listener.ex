defmodule EventPiper.EventListener do

  use GenServer

  require Logger

  @topic EventPiper.topic

  def start_link(_opts) do
    Logger.info("Listening on PG channel '#{@topic}'...")

    GenServer.start_link(__MODULE__, @topic, name: __MODULE__)
  end

  def init(channel) do
    with {:ok, pid, ref} <- EventPiper.Repo.listen(channel) do
      {:ok, {pid, ref}}
    else
      error -> {:stop, error}
    end
  end

  def handle_info({:notification, pid, ref, channel, payload}, {pid, ref} = state) do
    Logger.info("[#{channel}]: #{payload}")
    PubSub.publish(channel, {channel, payload})

    {:noreply, state}
  end

end
