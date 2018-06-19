module RubyEventStore
  module PubSub

    class Dispatcher
      def call(subscriber, event, serialized_event)
        subscriber = subscriber.new if Class === subscriber
        subscriber.call(event)
      end

      def verify(subscriber)
        subscriber = klassify(subscriber)
        subscriber.respond_to?(:call) or raise InvalidHandler.new(subscriber)
      end

      private

      def klassify(subscriber)
        Class === subscriber ? subscriber.new : subscriber
      rescue ArgumentError
        raise InvalidHandler.new(subscriber)
      end
    end

  end
end
