defmodule EventPiper.EventListener do

  @moduledoc """
  We use a GenServer (single process) to handle all the PostgreSQL notifications so that we would consume only
  1 database connection for the whole service instance. It sends again the notifications to the processes which
  subscribe to the specific @topic.
  """

  use GenServer

  require Logger

  @topic EventPiper.topic

  def start_link(_opts) do
    Logger.info("Listening on PG channel '#{@topic}'...")

    GenServer.start_link(__MODULE__, @topic, name: __MODULE__)
  end

  def init(topic) do
    with {:ok, pid, ref} <- EventPiper.Repo.listen(topic) do
      {:ok, {pid, ref}}
    else
      error -> {:stop, error}
    end
  end

  # All the PostgreSQL notifications will be handled here
  def handle_info({:notification, pid, ref, topic, payload}, {pid, ref} = state) do
    Logger.info("[#{topic}]: #{payload}")

    event = Jason.decode!(payload, keys: :atoms)
    PubSub.publish(topic, {event.subscriber, event})

    {:noreply, state}
  end

end
