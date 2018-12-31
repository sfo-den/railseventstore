---
title: Migrating existing events
---

Sometimes it is convenient to update existing historical events. Instead of introducing a new event in a different version (`SomethingHappened-v2`), we might prefer the simplicity of adding a new field to existing events via migration. Such as for example `tenant_id` when we introduce multi-tenancy to our application. There are various tread-offs here (you are rewriting a history after all), but we assume you understand them well if you decide to go this way.

Another valid use-case can be when you decide to migrate to a different mapper (ie from YAML to Protobuf).

Note that events are updated using "upsert" capabilities of your MySQL, PostgreSQL or Sqlite 3.24.0+ database.

### Add data and metadata to existing events

```ruby
event_store.read.in_batches.each_batch do |events|
  events.each do |ev|
    ev.data[:tenant_id] = 1
    ev.metadata[:server_id] = "eu-west-2"
  end
  event_store.overwrite(events)
end
```

### Change event type

```ruby
event_store.read.in_batches.each_batch do |events|
  events.select{|ev| OldType === ev }.map do |ev|
    NewType.new(
      event_id: ev.event_id,
      data: ev.data,
      metadata: ev.metadata,
    )
  end
  event_store.overwrite(events)
end
```
