# Rails Event Store

[Rails Event Store (RES)](https://railseventstore.org/) is a library for publishing, consuming, storing and retrieving events. It's your best companion for going with an event-driven architecture for your Rails application.

You can use it:

<ul>
<li>as your <a href="https://railseventstore.org/docs/pubsub/">Publish-Subscribe bus</a></li>
<li>to decouple core business logic from external concerns in Hexagonal style architectures</li>
<li>as <a href="https://blog.arkency.com/2016/05/domain-events-over-active-record-callbacks/">an alternative to ActiveRecord callbacks and Observers</a></li>
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

This single repository hosts several gems and website with documentation — see the [contribution guide](https://railseventstore.org/contributing/).

We're aiming for 100% mutation coverage in this project. This is why:

* [Why I want to introduce mutation testing to the rails_event_store gem](https://blog.arkency.com/2015/04/why-i-want-to-introduce-mutation-testing-to-the-rails-event-store-gem/)
* [Mutation testing and continuous integration](https://blog.arkency.com/2015/05/mutation-testing-and-continuous-integration/)

Whenever you fix a bug or add a new feature, we require that the coverage doesn't go down.

### RailsEventStore gems


|  Name | CI | Version | Downloads |
|---|---|---|---|
| [rails_event_store](/rails_event_store) | [![GitHub Workflow Status](https://img.shields.io/github/workflow/status/RailsEventStore/rails_event_store/rails_event_store?style=flat-square)](https://github.com/RailsEventStore/rails_event_store/actions/workflows/rails_event_store.yml) | [![Gem](https://img.shields.io/gem/v/rails_event_store?style=flat-square)](https://rubygems.org/gems/rails_event_store) | [![Gem](https://img.shields.io/gem/dt/rails_event_store?style=flat-square)](https://rubygems.org/gems/rails_event_store) |
| [rails_event_store_active_record](/rails_event_store_active_record) | [![GitHub Workflow Status](https://img.shields.io/github/workflow/status/RailsEventStore/rails_event_store/rails_event_store_active_record?style=flat-square)](https://github.com/RailsEventStore/rails_event_store/actions/workflows/rails_event_store_active_record.yml) | [![Gem](https://img.shields.io/gem/v/rails_event_store_active_record?style=flat-square)](https://rubygems.org/gems/rails_event_store_active_record) | [![Gem](https://img.shields.io/gem/dt/rails_event_store_active_record?style=flat-square)](https://rubygems.org/gems/rails_event_store_active_record) |
| [ruby_event_store](/ruby_event_store) | [![GitHub Workflow Status](https://img.shields.io/github/workflow/status/RailsEventStore/rails_event_store/ruby_event_store?style=flat-square)](https://github.com/RailsEventStore/rails_event_store/actions/workflows/ruby_event_store.yml) | [![Gem](https://img.shields.io/gem/v/ruby_event_store?style=flat-square)](https://rubygems.org/gems/ruby_event_store) | [![Gem](https://img.shields.io/gem/dt/ruby_event_store?style=flat-square)](https://rubygems.org/gems/ruby_event_store) |
| [ruby_event_store-browser](/ruby_event_store-browser) | [![GitHub Workflow Status](https://img.shields.io/github/workflow/status/RailsEventStore/rails_event_store/ruby_event_store-browser?style=flat-square)](https://github.com/RailsEventStore/rails_event_store/actions/workflows/ruby_event_store-browser.yml) | [![Gem](https://img.shields.io/gem/v/ruby_event_store-browser?style=flat-square)](https://rubygems.org/gems/ruby_event_store-browser) | [![Gem](https://img.shields.io/gem/dt/ruby_event_store-browser?style=flat-square)](https://rubygems.org/gems/ruby_event_store-browser) |
| [ruby_event_store-rspec](/ruby_event_store-rspec) | [![GitHub Workflow Status](https://img.shields.io/github/workflow/status/RailsEventStore/rails_event_store/ruby_event_store-rspec?style=flat-square)](https://github.com/RailsEventStore/rails_event_store/actions/workflows/ruby_event_store-rspec.yml) | [![Gem](https://img.shields.io/gem/v/ruby_event_store-rspec?style=flat-square)](https://rubygems.org/gems/ruby_event_store-rspec) | [![Gem](https://img.shields.io/gem/dt/ruby_event_store-rspec?style=flat-square)](https://rubygems.org/gems/ruby_event_store-rspec) |
| [aggregate_root](/aggregate_root) | [![GitHub Workflow Status](https://img.shields.io/github/workflow/status/RailsEventStore/rails_event_store/aggregate_root?style=flat-square)](https://github.com/RailsEventStore/rails_event_store/actions/workflows/aggregate_root.yml) | [![Gem](https://img.shields.io/gem/v/aggregate_root?style=flat-square)](https://rubygems.org/gems/aggregate_root) | [![Gem](https://img.shields.io/gem/dt/aggregate_root?style=flat-square)](https://rubygems.org/gems/aggregate_root) |


### Contributed gems

|  Name | CI | Version | Downloads |
|---|---|---|---|
| [ruby_event_store-outbox](/contrib/ruby_event_store-outbox) | [![GitHub Workflow Status](https://img.shields.io/github/workflow/status/RailsEventStore/rails_event_store/ruby_event_store-outbox?style=flat-square)](https://github.com/RailsEventStore/rails_event_store/actions/workflows/ruby_event_store-outbox.yml) |  [![Gem](https://img.shields.io/gem/v/ruby_event_store-outbox?style=flat-square)](https://rubygems.org/gems/ruby_event_store-outbox) |  [![Gem](https://img.shields.io/gem/dt/ruby_event_store-outbox?style=flat-square)](https://rubygems.org/gems/ruby_event_store-outbox) |
| [ruby_event_store-protobuf](/contrib/ruby_event_store-protobuf) | [![GitHub Workflow Status](https://img.shields.io/github/workflow/status/RailsEventStore/rails_event_store/ruby_event_store-protobuf?style=flat-square)](https://github.com/RailsEventStore/rails_event_store/actions/workflows/ruby_event_store-protobuf.yml) |  [![Gem](https://img.shields.io/gem/v/ruby_event_store-protobuf?style=flat-square)](https://rubygems.org/gems/ruby_event_store-protobuf) |  [![Gem](https://img.shields.io/gem/dt/ruby_event_store-protobuf?style=flat-square)](https://rubygems.org/gems/ruby_event_store-protobuf) |
| [ruby_event_store-newrelic](/contrib/ruby_event_store-newrelic) | [![GitHub Workflow Status](https://img.shields.io/github/workflow/status/RailsEventStore/rails_event_store/ruby_event_store-newrelic?style=flat-square)](https://github.com/RailsEventStore/rails_event_store/actions/workflows/ruby_event_store-newrelic.yml) |  [![Gem](https://img.shields.io/gem/v/ruby_event_store-newrelic?style=flat-square)](https://rubygems.org/gems/ruby_event_store-newrelic) |  [![Gem](https://img.shields.io/gem/dt/ruby_event_store-newrelic?style=flat-square)](https://rubygems.org/gems/ruby_event_store-newrelic) |
| [ruby_event_store-profiler](/contrib/ruby_event_store-profiler) | [![GitHub Workflow Status](https://img.shields.io/github/workflow/status/RailsEventStore/rails_event_store/ruby_event_store-profiler?style=flat-square)](https://github.com/RailsEventStore/rails_event_store/actions/workflows/ruby_event_store-profiler.yml) |  [![Gem](https://img.shields.io/gem/v/ruby_event_store-profiler?style=flat-square)](https://rubygems.org/gems/ruby_event_store-profiler) |  [![Gem](https://img.shields.io/gem/dt/ruby_event_store-profiler?style=flat-square)](https://rubygems.org/gems/ruby_event_store-profiler) |
| [ruby_event_store-flipper](/contrib/ruby_event_store-flipper) | [![GitHub Workflow Status](https://img.shields.io/github/workflow/status/RailsEventStore/rails_event_store/ruby_event_store-flipper?style=flat-square)](https://github.com/RailsEventStore/rails_event_store/actions/workflows/ruby_event_store-flipper.yml) |  [![Gem](https://img.shields.io/gem/v/ruby_event_store-flipper?style=flat-square)](https://rubygems.org/gems/ruby_event_store-flipper) |  [![Gem](https://img.shields.io/gem/dt/ruby_event_store-flipper?style=flat-square)](https://rubygems.org/gems/ruby_event_store-flipper) |
| [ruby_event_store-transformations](/contrib/ruby_event_store-transformations) | [![GitHub Workflow Status](https://img.shields.io/github/workflow/status/RailsEventStore/rails_event_store/ruby_event_store-transformations?style=flat-square)](https://github.com/RailsEventStore/rails_event_store/actions/workflows/ruby_event_store-transformations.yml) |  [![Gem](https://img.shields.io/gem/v/ruby_event_store-transformations?style=flat-square)](https://rubygems.org/gems/ruby_event_store-transformations) |  [![Gem](https://img.shields.io/gem/dt/ruby_event_store-transformations?style=flat-square)](https://rubygems.org/gems/ruby_event_store-transformations) |
| [ruby_event_store-rom](/contrib/ruby_event_store-rom) | [![GitHub Workflow Status](https://img.shields.io/github/workflow/status/RailsEventStore/rails_event_store/ruby_event_store-rom?style=flat-square)](https://github.com/RailsEventStore/rails_event_store/actions/workflows/ruby_event_store-rom.yml) |  [![Gem](https://img.shields.io/gem/v/ruby_event_store-rom?style=flat-square)](https://rubygems.org/gems/ruby_event_store-rom) |  [![Gem](https://img.shields.io/gem/dt/ruby_event_store-rom?style=flat-square)](https://rubygems.org/gems/ruby_event_store-rom) |
| [ruby_event_store-sidekiq_scheduler](/contrib/ruby_event_store-sidekiq_scheduler) | [![GitHub Workflow Status](https://img.shields.io/github/workflow/status/RailsEventStore/rails_event_store/ruby_event_store-sidekiq_scheduler?style=flat-square)](https://github.com/RailsEventStore/rails_event_store/actions/workflows/ruby_event_store-sidekiq_scheduler.yml) |  [![Gem](https://img.shields.io/gem/v/ruby_event_store-sidekiq_scheduler?style=flat-square)](https://rubygems.org/gems/ruby_event_store-sidekiq_scheduler) |  [![Gem](https://img.shields.io/gem/dt/ruby_event_store-sidekiq_scheduler?style=flat-square)](https://rubygems.org/gems/ruby_event_store-sidekiq_scheduler) |
| [minitest-ruby_event_store](/contrib/minitest-ruby_event_store) | [![GitHub Workflow Status](https://img.shields.io/github/workflow/status/RailsEventStore/rails_event_store/minitest-ruby_event_store?style=flat-square)](https://github.com/RailsEventStore/rails_event_store/actions/workflows/minitest-ruby_event_store.yml) |  [![Gem](https://img.shields.io/gem/v/minitest-ruby_event_store?style=flat-square)](https://rubygems.org/gems/minitest-ruby_event_store) |  [![Gem](https://img.shields.io/gem/dt/minitest-ruby_event_store?style=flat-square)](https://rubygems.org/gems/minitest-ruby_event_store) |
| [dres_rails](/contrib/distributed_rails_event_store/dres_rails) | [![GitHub Workflow Status](https://img.shields.io/github/workflow/status/RailsEventStore/rails_event_store/dres_rails?style=flat-square)](https://github.com/RailsEventStore/rails_event_store/actions/workflows/dres_rails.yml) |  [![Gem](https://img.shields.io/gem/v/dres_rails?style=flat-square)](https://rubygems.org/gems/dres_rails) |  [![Gem](https://img.shields.io/gem/dt/dres_rails?style=flat-square)](https://rubygems.org/gems/dres_rails) |
| [dres_client](/contrib/distributed_rails_event_store/dres_client) | [![GitHub Workflow Status](https://img.shields.io/github/workflow/status/RailsEventStore/rails_event_store/dres_client?style=flat-square)](https://github.com/RailsEventStore/rails_event_store/actions/workflows/dres_client.yml) |  [![Gem](https://img.shields.io/gem/v/dres_client?style=flat-square)](https://rubygems.org/gems/dres_client) |  [![Gem](https://img.shields.io/gem/dt/dres_client?style=flat-square)](https://rubygems.org/gems/dres_client) |


## About

<img src="https://arkency.com/logo.svg" alt="Arkency" height="48" align="left" />

This repository is funded and maintained by [arkency](https://arkency.com). Make sure to check out our [Rails Architect Masterclass training](https://arkademy.dev) and long-term [support plans](https://railseventstore.org/support/) available.
