[![Build Status](https://travis-ci.org/arkency/rails_event_store.svg?branch=master)](https://travis-ci.org/arkency/rails_event_store)
[![Gem Version](https://badge.fury.io/rb/rails_event_store.svg)](http://badge.fury.io/rb/rails_event_store)
[![Code Climate](https://codeclimate.com/github/arkency/rails_event_store/badges/gpa.svg)](https://codeclimate.com/github/arkency/rails_event_store)
[![Test Coverage](https://codeclimate.com/github/arkency/rails_event_store/badges/coverage.svg)](https://codeclimate.com/github/arkency/rails_event_store)
[![Join the chat at https://gitter.im/arkency/rails_event_store](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/arkency/rails_event_store?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

# EventStore

A Ruby implementation of an EventStore.
Default storage is events repository based on Active Record (provided by separate gem: [rails_event_store_active_record](http://github.com/arkency/rails_event_store_active_record)).

# Documentation

All documentation and sample codes are available at [http://railseventstore.arkency.com](http://railseventstore.arkency.com). If you'd like to contribute by writing or maintaining docs, they're stored in the `gh-pages` branch in this repository.


# Contributing

Check the contribution guide on [CONTRIBUTING.md](https://github.com/arkency/rails_event_store/blob/master/CONTRIBUTING.md)

We're aiming for 100% mutation coverage in this project.
Read the reasoning:

[Why I want to introduce mutation testing to the rails_event_store gem](http://blog.arkency.com/2015/04/why-i-want-to-introduce-mutation-testing-to-the-rails-event-store-gem/)

[Mutation testing and continuous integration](http://blog.arkency.com/2015/05/mutation-testing-and-continuous-integration/)

In practice, it means that we run `make mutate` as part of the CI process.
Whenever you fix a bug or add a new feature, we require that the coverage doesn't go down.

## About

<img src="http://arkency.com/images/arkency.png" alt="Arkency" width="20%" align="left" />

Rails Event Store is funded and maintained by Arkency. Check out our other [open-source projects](https://github.com/arkency).

You can also [hire us](http://arkency.com) or [read our blog](http://blog.arkency.com).
