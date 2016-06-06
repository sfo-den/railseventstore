require 'spec_helper'

module RubyEventStore
  describe Projection do
    MoneyDeposited = Class.new(RubyEventStore::Event)
    MoneyWithdrawn = Class.new(RubyEventStore::Event)

    let(:event_store) { RubyEventStore::Facade.new(InMemoryRepository.new) }

    specify "reduce events from one stream" do
      stream_name = "Customer$123"
      event_store.publish_event(MoneyDeposited.new(amount: 10), stream_name)
      event_store.publish_event(MoneyDeposited.new(amount: 20), stream_name)
      event_store.publish_event(MoneyWithdrawn.new(amount: 5),  stream_name)
      account_balance = Projection.
        from_stream(stream_name).
        init( -> { { total: 0 } }).
        when(MoneyDeposited, ->(state, event) { state[:total] += event.amount }).
        when(MoneyWithdrawn, ->(state, event) { state[:total] -= event.amount }).
        run(event_store)
      expect(account_balance).to eq(total: 25)
    end

    specify "reduce events from many streams" do
      event_store.publish_event(MoneyDeposited.new(amount: 10), "Customer$1")
      event_store.publish_event(MoneyDeposited.new(amount: 20), "Customer$2")
      event_store.publish_event(MoneyWithdrawn.new(amount: 5),  "Customer$3")
      account_balance = Projection.
        from_stream("Customer$1", "Customer$3").
        init( -> { { total: 0 } }).
        when(MoneyDeposited, ->(state, event) { state[:total] += event.amount }).
        when(MoneyWithdrawn, ->(state, event) { state[:total] -= event.amount }).
        run(event_store)
      expect(account_balance).to eq(total: 5)
    end

    specify "limit events from many streams" do
      event_store.publish_event(MoneyDeposited.new(amount: 15), "Customer$1")
      event_store.publish_event(MoneyDeposited.new(amount: 25), "Customer$2")
      event_store.publish_event(custom_event = MoneyWithdrawn.new(amount: 10), "Customer$3")
      event_store.publish_event(MoneyWithdrawn.new(amount: 20), "Customer$3")

      account_balance = Projection.
        from_stream("Customer$1", "Customer$3").
        init( -> { { total: 0 } }).
        when(MoneyDeposited, ->(state, event) { state[:total] += event.amount }).
        when(MoneyWithdrawn, ->(state, event) { state[:total] -= event.amount })

      expect(account_balance.call(event_store)).to eq(total: -15)
      expect(account_balance.call(event_store, :head)).to eq(total: -15)
      expect(account_balance.call(event_store, [:head, custom_event.event_id], 1)).to eq(total: -5)
    end

    specify "raises proper errors when wrong argument were pass (stream mode)" do
      projection = Projection.from_stream("Customer$1", "Customer$2")
      expect {
        projection.call(event_store, :last)
      }.to raise_error ArgumentError, 'Start must be an array with event ids or :head'
      expect {
        projection.call(event_store, 0.7)
      }.to raise_error ArgumentError, 'Start must be an array with event ids or :head'
      expect {
        projection.call(event_store, [SecureRandom.uuid])
      }.to raise_error ArgumentError, 'Start must be an array with event ids or :head'
    end

    specify "take events from all streams" do
      event_store.publish_event(MoneyDeposited.new(amount: 1), "Customer$1")
      event_store.publish_event(MoneyDeposited.new(amount: 1), "Customer$2")
      event_store.publish_event(MoneyDeposited.new(amount: 1), "Customer$3")
      event_store.publish_event(MoneyWithdrawn.new(amount: 2), "Customer$4")

      account_balance = Projection.
        from_all_streams.
        init( -> { { total: 0 } }).
        when(MoneyDeposited, ->(state, event) { state[:total] += event.amount }).
        when(MoneyWithdrawn, ->(state, event) { state[:total] -= event.amount })

      expect(account_balance.call(event_store)).to eq(total: 1)
    end

    specify "limit events from all streams" do
      event_store.publish_event(MoneyDeposited.new(amount: 10), "Customer$1")
      event_store.publish_event(custom_event = MoneyDeposited.new(amount: 20), "Customer$2")
      event_store.publish_event(MoneyWithdrawn.new(amount: 5), "Customer$3")
      event_store.publish_event(MoneyDeposited.new(amount: 10), "Customer$4")

      account_balance = Projection.
        from_all_streams.
        init( -> { { total: 0 } }).
        when(MoneyDeposited, ->(state, event) { state[:total] += event.amount }).
        when(MoneyWithdrawn, ->(state, event) { state[:total] -= event.amount })

      expect(account_balance.call(event_store, custom_event.event_id, 1)).to eq(total: -5)
      expect(account_balance.call(event_store, custom_event.event_id, 2)).to eq(total: 5)
    end

    specify "raises proper errors when wrong argument were pass (all streams mode)" do
      projection = Projection.from_all_streams
      expect {
        projection.call(event_store, :last)
      }.to raise_error ArgumentError, 'Start must be valid event id or :head'
      expect {
        projection.call(event_store, 0.7)
      }.to raise_error ArgumentError, 'Start must be valid event id or :head'
      expect {
        projection.call(event_store, [SecureRandom.uuid])
      }.to raise_error ArgumentError, 'Start must be valid event id or :head'
    end

    specify "empty hash is default inital state" do
      stream_name = "Customer$123"
      event_store.publish_event(MoneyDeposited.new(amount: 10), stream_name)
      event_store.publish_event(MoneyDeposited.new(amount: 20), stream_name)
      event_store.publish_event(MoneyWithdrawn.new(amount: 5),  stream_name)
      stats = Projection.
        from_stream(stream_name).
        when(MoneyDeposited, ->(state, event) { state[:last_deposit]    = event.amount }).
        when(MoneyWithdrawn, ->(state, event) { state[:last_withdrawal] = event.amount }).
        run(event_store)
      expect(stats).to eq(last_deposit: 20, last_withdrawal: 5)
    end

    specify "ignore unhandled events" do
      stream_name = "Customer$123"
      event_store.publish_event(MoneyDeposited.new(amount: 10), stream_name)
      event_store.publish_event(MoneyWithdrawn.new(amount: 2), stream_name)
      deposits = Projection.
        from_stream(stream_name).
        init( -> { { total: 0 } }).
        when(MoneyDeposited, ->(state, event) { state[:total] += event.amount }).
        run(event_store)
      expect(deposits).to eq(total: 10)
    end

    specify "subscribe to events" do
      stream_name = "Customer$123"
      deposits = Projection.
        from_stream(stream_name).
        init( -> { { total: 0 } }).
        when(MoneyDeposited, ->(state, event) { state[:total] += event.amount })
      event_store.subscribe(deposits, deposits.handled_events)
      event_store.publish_event(MoneyDeposited.new(amount: 10), stream_name)
      event_store.publish_event(MoneyDeposited.new(amount: 5), stream_name)
      expect(deposits.current_state).to eq(total: 15)
    end

    specify "using default constructor" do
      expect { Projection.new("Customer$123") }.to raise_error(NoMethodError, /private method `new'/)
    end

    specify "at least one stream must be given" do
      expect { Projection.from_stream }.
        to raise_error(ArgumentError, "At least one stream must be given")
    end
  end
end
