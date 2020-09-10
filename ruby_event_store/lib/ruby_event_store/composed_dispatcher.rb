# frozen_string_literal: true

module RubyEventStore
  class ComposedDispatcher
    def initialize(*dispatchers)
      @dispatchers = dispatchers
    end

    def call(subscriber, event, record)
      @dispatchers.each do |dispatcher|
        if dispatcher.verify(subscriber)
          dispatcher.call(subscriber, event, record)
          break
        end
      end
    end

    def verify(subscriber)
      @dispatchers.any? do |dispatcher|
        dispatcher.verify(subscriber)
      end
    end
  end
end
