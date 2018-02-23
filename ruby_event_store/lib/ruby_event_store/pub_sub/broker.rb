require 'concurrent'

module RubyEventStore
  module PubSub
    class Broker
      DEFAULT_DISPATCHER = Dispatcher.new

      def initialize(dispatcher: DEFAULT_DISPATCHER)
        @subscribers = Hash.new {|hsh, key| hsh[key] = [] }
        @global_subscribers = []

        @thread_global_subscribers = Concurrent::ThreadLocalVar.new([])
        @thread_subscribers = Concurrent::ThreadLocalVar.new do
          Hash.new {|hsh, key| hsh[key] = [] }
        end

        @dispatcher = dispatcher
      end

      def dup
        self.class.new(dispatcher: @dispatcher).tap do |broker|
          hash = @subscribers.dup
          broker.instance_variable_set(:@subscribers, hash.update(hash){|k,v| v.dup })
          broker.instance_variable_set(:@global_subscribers, @global_subscribers.dup)
        end
      end

      def add_subscriber(subscriber, event_types)
        verify_subscriber(subscriber)
        subscribe(subscriber, event_types)
      end

      def add_global_subscriber(subscriber)
        verify_subscriber(subscriber)
        @global_subscribers << subscriber

        ->() { @global_subscribers.delete(subscriber) }
      end

      def add_thread_global_subscriber(subscriber)
        verify_subscriber(subscriber)
        @thread_global_subscribers.value += [subscriber]

        ->() { @thread_global_subscribers.value -= [subscriber] }
      end

      def add_thread_subscriber(subscriber, event_types)
        verify_subscriber(subscriber)
        event_types.each{ |type| @thread_subscribers.value[type.name] << subscriber }
        ->() {event_types.each{ |type| @thread_subscribers.value.fetch(type.name).delete(subscriber) } }
      end

      def notify_subscribers(event)
        all_subscribers_for(event.class).each do |subscriber|
          @dispatcher.call(subscriber, event)
        end
      end

      private

      def verify_subscriber(subscriber)
        raise SubscriberNotExist if subscriber.nil?
        @dispatcher.verify(subscriber)
      end

      def subscribe(subscriber, event_types)
        event_types.each{ |type| @subscribers[type.name] << subscriber }
        ->() {event_types.each{ |type| @subscribers.fetch(type.name).delete(subscriber) } }
      end

      def all_subscribers_for(event_type)
        @subscribers[event_type.name] +
        @global_subscribers +
        @thread_global_subscribers.value +
        @thread_subscribers.value[event_type.name]
      end
    end
  end
end
