# Rails Event Store

[Rails Event Store (RES)](http://railseventstore.org/) is a library for publishing, consuming, storing and retrieving events. It's your best companion for going with an event-driven architecture for your Rails application.

You can use it:

<ul>
<li>as your <a href="http://railseventstore.org/docs/pubsub/">Publish-Subscribe bus</a></li>
<li>to decouple core business logic from external concerns in Hexagonal style architectures</li>
<li>as <a href="http://blog.arkency.com/2016/05/domain-events-over-active-record-callbacks/">an alternative to ActiveRecord callbacks and Observers</a></li>
<li>as a communication layer between loosely coupled components</li>
<li>to react to published events synchronously or asynchronously</li>
<li>to extract side-effects (notifications, metrics etc) from your controllers and services into event handlers</li>
<li>to build an audit-log</li>
<li>to create read-models</li>
<li>to implement event-sourcing</li>
</ul>

## Documentation

Documentation, tutorials and code samples are available at [https://railseventstore.org](https://railseventstore.org).

## Code status

[![Build Status](https://travis-ci.org/RailsEventStore/rails_event_store.svg?branch=master)](https://travis-ci.org/RailsEventStore/rails_event_store)
[![Gem Version](https://badge.fury.io/rb/rails_event_store.svg)](http://badge.fury.io/rb/rails_event_store)

We're aiming for 100% mutation coverage in this project. This is why:

* [Why I want to introduce mutation testing to the rails_event_store gem](http://blog.arkency.com/2015/04/why-i-want-to-introduce-mutation-testing-to-the-rails-event-store-gem/)
* [Mutation testing and continuous integration](http://blog.arkency.com/2015/05/mutation-testing-and-continuous-integration/)

Whenever you fix a bug or add a new feature, we require that the coverage doesn't go down.

## Contributing

This single repository hosts several gems. Check the contribution [guide](https://railseventstore.org/contributing/). Documentation sources can be found in [another repository](https://github.com/RailsEventStore/railseventstore.org).

## About

<img src="http://arkency.com/images/arkency.png" alt="Arkency" width="60px" align="left" />

This repository is funded and maintained by [Arkency](https://arkency.com). Check out our other [open-source projects](https://github.com/arkency).

Consider [hiring us](http://arkency.com/hire-us) and make sure to check out [our blog](http://blog.arkency.com).

### Learn more about DDD & Event Sourcing

Check our [Rails + Domain Driven Design Workshop](http://blog.arkency.com/ddd-training/).
Why You should attend? Robert has explained this in a [blogpost](http://blog.arkency.com/2016/12/why-would-you-even-want-to-listen-about-ddd/).


Next edition will be held on **21-22th September 2017** in **Berlin, Germany**. Workshop will be held in English.


Another edition is also planned for November in London.

### Read about Domain Driven Rails

You may also consider buying the [Domain-Driven Rails book](http://blog.arkency.com/domain-driven-rails/).
