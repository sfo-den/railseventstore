# AggregateRoot

Event sourced (with Rails Event Store) aggregate root implementation.

## Installation

* Add following line to your application's Gemfile:

```ruby
gem 'aggregate_root'
```

## Before use

Choose your weapon now! Ekhm I mean choose your event store client.
To do so add configuration in environment setup. Example using [RailsEventStore](https://github.com/RailsEventStore/rails_event_store/):

```ruby
AggregateRoot.configure do |config|
  config.default_event_store = RailsEventStore::Client.new
end
```

Remember that this is only a default event store used by `AggregateRoot` module when no event store is given in `load` / `store` methods parameters.

To use [RailsEventStore](https://github.com/RailsEventStore/rails_event_store/) add to Gemfile:

```ruby
gem 'rails_event_store'
```

Then setup [RailsEventStore](https://github.com/RailsEventStore/rails_event_store/) as described in
the [docs](https://railseventstore.org/docs/install/)

## Usage

To create a new aggregate domain object include `AggregateRoot::Base` module.
It is important to assign `id` at initializer - it will be used as a event store stream name.

```ruby
class Order
  include AggregateRoot

  # ... more later
end
```

#### Define aggregate logic

```ruby
OrderSubmitted = Class.new(RailsEventStore::Event)
OrderExpired   = Class.new(RailsEventStore::Event)
```

```ruby
class Order
  include AggregateRoot
  HasBeenAlreadySubmitted = Class.new(StandardError)
  HasExpired              = Class.new(StandardError)

  def initialize
    self.state = :new
    # any other code here
  end

  def submit
    raise HasBeenAlreadySubmitted if state == :submitted
    raise HasExpired if state == :expired
    apply OrderSubmitted.new(data: {delivery_date: Time.now + 24.hours})
  end

  def expire
    apply OrderExpired.new
  end

  private
  attr_accessor :state

  def apply_order_submitted(event)
    self.state = :submitted
  end

  def apply_order_expired(event)
    self.state = :expired
  end
end
```

#### Loading an aggregate root object from event store

```ruby
stream_name = "Order$123"
order = Order.new.load(stream_name)
```

Load gets all domain event stored for the aggregate in event store and apply them
in order to given aggregate to rebuild aggregate's state.

#### Storing an aggregate root's changes in event store

```ruby
stream_name = "Order$123"
order = Order.new.load(stream_name)
order.submit
order.store
```

Store gets all unpublished aggregate's domain events (created by executing a domain logic method like `submit`)
and publish them in order of creation to event store. If `stream_name` is not specified events will be stored
in the same stream from which order has been loaded.

#### Resources

There're already few blog posts about building an event sourced applications with [rails_event_store](https://github.com/RailsEventStore/rails_event_store) and aggregate_root gems:

* [Why use Event Sourcing](https://blog.arkency.com/2015/03/why-use-event-sourcing/)
* [The Event Store for Rails developers](https://blog.arkency.com/2015/04/the-event-store-for-rails-developers/)
* [Fast introduction to Event Sourcing for Ruby programmers](https://blog.arkency.com/2015/03/fast-introduction-to-event-sourcing-for-ruby-programmers/)
* [Building an Event Sourced application using rails_event_store](https://blog.arkency.com/2015/05/building-an-event-sourced-application-using-rails-event-store/)
* [Using domain events as success/failure messages](https://blog.arkency.com/2015/05/using-domain-events-as-success-slash-failure-messages/)
* [Subscribing for events in rails_event_store](https://blog.arkency.com/2015/06/subscribing-for-events-in-rails-event-store/)
* [Testing an Event Sourced application](https://blog.arkency.com/2015/07/testing-event-sourced-application/)
* [Testing Event Sourced application - the read side](https://blog.arkency.com/2015/09/testing-event-sourced-application-the-read-side/)
* [One event to rule them all](https://blog.arkency.com/2016/01/one-event-to-rule-them-all/)
