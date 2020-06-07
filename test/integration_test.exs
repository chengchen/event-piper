defmodule EventPiper.IntegrationTest do

  use ExUnit.Case, async: true

  alias EventPiper.Repo
  alias Mint.HTTP

  test "health check" do
    {:ok, conn} = HTTP.connect(:http, "localhost", 4000)
    {:ok, conn, _ref} = HTTP.request(conn, "GET", "/manage/health", [], nil)
    {_conn, response} = stream_response(conn)

    assert response[:status] == 200
    assert response[:data] == "{\"status\":\"UP\"}"
  end

  test "not found" do
    {:ok, conn} = HTTP.connect(:http, "localhost", 4000)
    {:ok, conn, _ref} = HTTP.request(conn, "GET", "/any", [], nil)
    {_conn, response} = stream_response(conn)

    assert response[:status] == 404
  end

  test "non-authenticated request" do
    {:ok, conn} = HTTP.connect(:http, "localhost", 4000)
    {:ok, conn, _ref} = HTTP.request(conn, "GET", "/events", [], nil)
    {_conn, response} = stream_response(conn)

    assert response[:status] == 401
  end

  test "insert new events and get notified" do
    {:ok, conn} = HTTP.connect(:http, "localhost", 4000)
    {:ok, conn, _ref} = HTTP.request(conn, "GET", "/events", [{"x-consumer-id", "toto"}], nil)
    {conn, response} = stream_response(conn)

    assert response[:status] == 200
    assert_proper_header(response)

    Repo.insert_event!("toto", %{foo: "bar"})

    {conn, response} = stream_response(conn)

    assert response[:data] |> String.contains?("event: insert\ndata: {\"foo\":\"bar\"}")

    Repo.insert_event!("toto", %{bar: "foo"})

    {_conn, response} = stream_response(conn)

    assert response[:data] |> String.contains?("event: insert\ndata: {\"bar\":\"foo\"}")

    Repo.reset_all!
  end

  test "play back historical events and still get notified for new ones" do
    Repo.insert_event!("toto", %{ignored: "first event"})
    Repo.insert_event!("toto", %{ignored: "second event"})
    Repo.insert_event!("toto", %{replayed: "third event"})

    {:ok, conn} = HTTP.connect(:http, "localhost", 4000)
    {:ok, conn, _ref} = HTTP.request(conn, "GET", "/events", [{"x-consumer-id", "toto"}, {"last-event-id", "2"}], nil)
    {conn, response} = stream_response(conn)

    assert response[:status] == 200
    assert_proper_header(response)

    {conn, response} = stream_response(conn)

    assert response[:data] |> String.contains?("event: insert\ndata: {\"replayed\":\"third event\"}")

    Repo.insert_event!("toto", %{notified: "new event"})

    {_conn, response} = stream_response(conn)

    assert response[:data] |> String.contains?("event: insert\ndata: {\"notified\":\"new event\"}")

    Repo.reset_all!
  end

  defp stream_response(conn) do
    receive do
      message ->
        {:ok, conn, response} = HTTP.stream(conn, message)

        # map responses into a more easily accessible structure
        mapped_response = response |> Enum.map(fn r ->
          case r do
            {key, _ref, value} -> {key, value}
            {:done, ref}       -> {:done, ref}
          end
        end) |> Enum.into(%{})

        {conn, mapped_response}
    end
  end

  defp assert_proper_header(response) do
    assert [
             {"cache-control", "no-cache"},
             {"content-type", "text/event-stream"},
             {"date", _date},
             {"server", _server},
             {"transfer-encoding", "chunked"}
           ] = response[:headers]
  end

end
