defmodule EventPiper.ApiRouter do

  @moduledoc """
  A simple Server-Sent Event API that streams events from notifications
  and at the same time allowing on-demand historical events fetching based
  on Last-Event-ID header (SSE specifications).
  """

  use Plug.Router

  plug :match
  plug :dispatch

  alias EventPiper.Repo

  @topic EventPiper.topic

  get "/events" do
    subscriber = List.first(conn |> get_req_header("x-consumer-id"))
    last_event_id = List.first(conn |> get_req_header("last-event-id"))

    if (subscriber == nil) do
      conn |> send_resp(401, "Request doesn't pass through the API gateway!")
    end

    conn = conn
           |> put_resp_header("Cache-Control", "no-cache")
           |> put_resp_header("Content-Type", "text/event-stream")
           |> send_chunked(200)

    PubSub.subscribe(self(), @topic)

    # Replay all the historical events from the last event ID
    if (last_event_id && is_integer_string(last_event_id)) do
      Repo.stream_events(subscriber, last_event_id, fn event -> conn |> send_event(event) end)
    end

    # Stream from notifications
    conn |> stream_events(subscriber)
  end

  get "/manage/health" do
    conn |> send_resp(200, to_json(%{status: "UP"}))
  end

  match _ do
    conn |> send_resp(404, "Not found")
  end

  # Recursively pattern-matching events on subscriber and send them via HTTP connection.
  # If there is no notifications during 10s, send a heartbeat event to
  # keep the connection alive
  defp stream_events(conn, subscriber) do
    receive do
      {^subscriber, event} ->
        conn |> send_event(event)
        stream_events(conn, subscriber)

      after 10_000 ->
        conn |> heartbeat
        stream_events(conn, subscriber)
    end
  end

  defp send_event(conn, event) do
    chunk(conn, """
                id: #{event.id}
                event: #{event.type}
                data: #{to_json(event.payload)}
                \n
                """)
  end

  defp heartbeat(conn) do
    chunk(conn, """
                event: heartbeat
                data: thump
                \n
                """)
  end

  defp is_integer_string(value) do
    case Integer.parse(value) do
      {_num, ""} -> true
      _ -> false
    end
  end

  defp to_json(data) do
    Jason.encode!(data)
  end

end
