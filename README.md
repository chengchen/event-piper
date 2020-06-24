# EventPiper

The service listens directly to PostgreSQL notification channel `new_events` and consume all the new events created in `events` table. The database
schema could be found in `postgresql/schema.sql` file. The service uses only 1 connection to digest all the notifications from PostgreSQL, and it
pipes the notifications to concerned live subscribers. So if we scale the services to n instances and share the load, they would consume only n connections
in normal usage (when on-demand historical events replay is not requested).

## Build and run tests

```
$ make build
```

## To run it without Elixir or PostgreSQL (need to run `make build` first)

```
$ make run
```

## Use the PUSH API

```
$ curl -v localhost:4000/events -H "X-Consumer-Id: toto"
```

You should not see anything but some heartbeat events.

Keep the previous call open. Now, let's create some events in the database:

```
$ docker exec -it postgresql bash

(in the container)
$ psql -d event_piper -U event_piper

(in psql)
# insert into events (type, timestamp, subscriber, payload) values ('insert', now(), 'toto', '{"foo": "bar"}');
```

You should see a new event in the previous terminal:

```
id: 1
event: insert
data: {"foo":"bar"}
```

You can create more and all the events should be pushed to the terminal directly.

## Historical events replay

In the case of a broken connection or missing events, we could use an extra header `Last-Event-ID` to go back in history and fetch the missing events.

```
$ curl -v localhost:4000/events -H "X-Consumer-Id: toto" -H "Last-Event-ID: 5"
```

You should see immediately some responses streamed from the database:

```
id: 6
event: insert
data: {"foo":"bar"}


id: 7
event: insert
data: {"foo":"bar"}


id: 8
event: insert
data: {"foo":"bar"}

...
```

## Java client example (with Reactor)

```java
WebClient client = WebClient.create("http://localhost:4000");
ParameterizedTypeReference<ServerSentEvent<String>> type = new ParameterizedTypeReference<ServerSentEvent<String>>() {};

Flux<ServerSentEvent<String>> eventStream = client.get()
    .uri("/events")
    .header("X-Consumer-Id", "toto")
    .header("Last-Event-Id", "4")
    .retrieve()
    .bodyToFlux(type);
```

Now, if you have 2 sessions open for `toto`, and you insert another event into the database, you should see the pushed event in both.

## TODO

* Database schema is very primitive. If we prefer an append-only approach, we should add more fields to allow event patching.
* Complete CI + proper config management
* The historical replay is using a PostgreSQL streaming approach, which could check out a connection for long time if the number of events is huge.
