defmodule EventPiper.ApiRouter do

  use Plug.Router
  alias EventPiper.Repo

  plug :match
  plug :dispatch

  @topic EventPiper.topic

  get "/events" do
    conn = conn |> send_chunked(200)

    PubSub.subscribe(self(), @topic)
    Repo.stream_events("toto", 5, fn e -> send_event(conn, Jason.encode!(e)) end)

    stream_events(conn)
  end

  defp stream_events(conn) do
    receive do
      {@topic, payload} ->
        send_event(conn, payload)

        # wait for next event
        stream_events(conn)
    end
  end

  defp send_event(conn, payload) do
    chunk(conn, "data: #{payload}\n\n")
  end

  match _ do
    send_resp(conn, 404, "Not found")
  end

end
