[![Build Status](https://travis-ci.org/arkency/aggregate_root.svg?branch=master)](https://travis-ci.org/arkency/aggregate_root)
[![Gem Version](https://badge.fury.io/rb/aggregate_root.svg)](https://badge.fury.io/rb/aggregate_root)
[![Code Climate](https://codeclimate.com/github/arkency/aggregate_root/badges/gpa.svg)](https://codeclimate.com/github/arkency/aggregate_root)
[![Test Coverage](https://codeclimate.com/github/arkency/aggregate_root/badges/coverage.svg)](https://codeclimate.com/github/arkency/aggregate_root/coverage)
[![Join the chat at https://gitter.im/arkency/rails_event_store](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/arkency/rails_event_store?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

# AggregateRoot

Event sourced (with Rails Event Store) aggregate root implementation.

## Installation

* Add following line to your application's Gemfile:

```ruby
gem 'aggregate_root'
```

## Before use

Choose your weapon now! Ekhm I mean choose your event store client.
To do so add configuration in environment setup. Example using [RailsEventStore](https://github.com/arkency/rails_event_store/):

```ruby
AggregateRoot.configure do |config|
  config.default_event_store = RailsEventStore::Client.new
end
```

Remember that this is only a default event store used by `AggregateRoot` module when no event store is given in `load` / `store` methods parameters.

To use [RailsEventStore](https://github.com/arkency/rails_event_store/) add to Gemfile:

```ruby
gem 'rails_event_store'
```

Then setup [RailsEventStore](https://github.com/arkency/rails_event_store/) as described in
Installation section of [readme](https://github.com/arkency/rails_event_store/blob/master/README.md#installation).

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

There're already few blog posts about building an event sourced applications with [rails_event_store](https://github.com/arkency/rails_event_store) and aggregate_root gems:

* [Why use Event Sourcing](http://blog.arkency.com/2015/03/why-use-event-sourcing/)
* [The Event Store for Rails developers](http://blog.arkency.com/2015/04/the-event-store-for-rails-developers/)
* [Fast introduction to Event Sourcing for Ruby programmers](http://blog.arkency.com/2015/03/fast-introduction-to-event-sourcing-for-ruby-programmers/)
* [Building an Event Sourced application using rails_event_store](http://blog.arkency.com/2015/05/building-an-event-sourced-application-using-rails-event-store/)
* [Using domain events as success/failure messages](http://blog.arkency.com/2015/05/using-domain-events-as-success-slash-failure-messages/)
* [Subscribing for events in rails_event_store](http://blog.arkency.com/2015/06/subscribing-for-events-in-rails-event-store/)
* [Testing an Event Sourced application](http://blog.arkency.com/2015/07/testing-event-sourced-application/)
* [Testing Event Sourced application - the read side](http://blog.arkency.com/2015/09/testing-event-sourced-application-the-read-side/)
* [One event to rule them all](http://blog.arkency.com/2016/01/one-event-to-rule-them-all/)

# Contributing

Check the contribution guide on [CONTRIBUTING.md](https://github.com/arkency/aggregate_root/blob/master/CONTRIBUTING.md)

We're aiming for 100% mutation coverage in this project.
Read the reasoning:

[Why I want to introduce mutation testing to the rails_event_store gem](http://blog.arkency.com/2015/04/why-i-want-to-introduce-mutation-testing-to-the-rails-event-store-gem/)

[Mutation testing and continuous integration](http://blog.arkency.com/2015/05/mutation-testing-and-continuous-integration/)

In practice, it means that we run `make mutate` as part of the CI process.
Whenever you fix a bug or add a new feature, we require that the coverage doesn't go down.

## About

<img src="http://arkency.com/images/arkency.png" alt="Arkency" width="60px" align="left" />

This repository is funded and maintained by Arkency. Check out our other [open-source projects](https://github.com/arkency).

You can also [hire us](http://arkency.com) or [read our blog](http://blog.arkency.com).


## Learn more about DDD & Event Sourcing

Check our **Rails + Domain Driven Design Workshop** [more details](http://blog.arkency.com/ddd-training/).

Why You should attend? Robert has explained this in [this blogpost](http://blog.arkency.com/2016/12/why-would-you-even-want-to-listen-about-ddd/).

Next edition will be held on **25-26th May 2017** (Thursday & Friday) in Lviv, Ukraine.
Workshop will be held in English.

