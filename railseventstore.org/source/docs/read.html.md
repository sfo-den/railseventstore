---
title: Reading events
---

## Specification of read scope

You could use a speciffication pattern to prepare a read scope.
The read scope defines what domain events will be read.

The available specification methods are:

* `stream(stream_name)` - specify name of a stream to read,
   if no stream will be specified a global stream (all domain events)
   will be read.
* `from(start)` - specify a starting point for read operation, possible values:
    * `:head`  - read from the beggining of the stream,
    * event id - read all domain events after specified domain event id.
* `forward`  - reading direction, from oldest to newest domain events.
* `backward` - reading direction, from newest to oldest  domain events.
* `limit(count)` - total number of events to read (could be less).
* `in_batches(batch_size)` - read will be performed in batches of specified size.
   RailsEventStore newer reads all domain events at once - event if you not specify
   batch size the read operation will read in batches of size 100.
* `of_type(types)` - read only specified types of domain events ignoring all others.

The read scope could be defined by chaining the specification methods, i.e.:

```ruby
scope = client.read
  .stream('GoldCustomers')
  .backward
  .limit(100)
  .of_type([Customer::GoldStatusGranted])
```

When the read scope will be defined several methods could be used to get the data:

* `count` - returns total number of domain events to be read.
* `each` - returns enumerator for all domain events in the read scope.
* `each_batch` - returns enumerator of batches of specified size (or 100 if no
   batch size have been specified).
* `to_a` - returns an array with all domain events from the scope, equals to `each.to_a`.
* `first` - returns first domain event from the read scope.
* `last` - returns last domain event from the read scope.
* `event(event_id)` - return event of given id if found in the read scope, otherwise `nil`.
* `event!(event_id)` - return event of given id if found in the read scope,
  otherwise raises `RubyEventStore::EventNotfound` error.
* `events(event_ids)` - returns list of domain events of given ids found in read scope,
  if there is no event of some event id it is ignored (not all domain events must be found).

## Examples

### Reading stream's events forward in batch — starting from first event

```ruby
stream_name = "order_1"
count = 40
client.read.stream(stream_name).from(:head).limit(count).to_a
```

In this case `:head` means first event of the stream.

### Reading stream's events forward in batch — starting from given event

```ruby
# last_read_event is any domain event read or published by rails_event_store

stream_name = "order_1"
start = last_read_event.event_id
count = 40
client.read.stream(stream_name).from(start).limit(count).to_a
```

### Reading stream's events backward in batch

As in examples above, just append `.backward` instead before `.each`.
In this case `:head` means last event of the stream.

```ruby
stream_name = "order_1"
start = last_read_event.event_id
count = 40
client.read.backward.stream(stream_name).from(start).limit(count).to_a
```

### Reading all events from stream forward

This method allows us to load all stream's events ascending.

```ruby
stream_name = "order_1"
client.read.stream(stream_name).to_a
```

### Reading all events from stream backward

This method allows us to load all stream's events descending.

```ruby
stream_name = "order_1"
client.read.backward.stream(stream_name).to_a
```

### Reading all events forward

This method allows us to load all stored events ascending.

This will read first 100 domain events stored in event store.

```ruby
client.read.from(:head).limit(100).to_a
```

When not specified it reads events starting from `:head` (first domain event
stored in event store) and without limit.

```ruby
client.read.to_a
```

You could also read batch of domain events starting from any read or published event.

```ruby
client.read.from(last_read_event.event_id).limit(100).to_a
```

### Reading all events backward

This method allows us to load all stored events descending.

This will read last 100 domain events stored in event store.

```ruby
client.read.backward.from(:head).limit(100).to_a
```

When not specified it reads events starting from `:head` (last domain event
stored in event store) and without limit.

```ruby
client.read.backward.to_a
```


## Reading specified events

RailsEventStore let's you read specific event (or a list of events).
You need to know ids of events you want to read.

Fetch a single event (will return a single domain event):

```ruby
client.read.event('some-event-id-here')
```

The `read.event` method will return `nil` if event cound not be found.
Use `read.event!` method to raise an `EventNotFound` error if event cound not be found.


Fetch a multiple events at once (will return an array of domain events):

```ruby
client.read.events(['event-1-id', 'event-2-id', ... 'event-N-id'])
```

The `read.events` method will return only existing events. If none of given ids
could not be found it will return empty collection.
