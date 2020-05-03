defmodule EventPiper.Repo do

  use Ecto.Repo,
      otp_app: :event_piper,
      adapter: Ecto.Adapters.Postgres

  import Ecto.Query, warn: false

  alias EventPiper.Event
  alias Postgrex.Notifications

  # Use one connection to listen to PostgreSQL notifications
  # All the notifications will be sent to the caller process mailbox
  def listen(channel) do
    with {:ok, connection_pid} <- Notifications.start_link(__MODULE__.config()),
         {_, reference} <- Notifications.listen(connection_pid, channel) do
      {:ok, connection_pid, reference}
    end
  end

  # Push event stream to a consumer in a single transaction
  def stream_events(subscriber, last_id, consumer) do
    transaction(
      fn () -> stream(from e in Event,
          where: e.subscriber == ^subscriber and e.id > ^last_id,
          order_by: [asc: :id]
        )
        |> Stream.each(consumer)
        |> Stream.run()
      end
    )
  end

end
