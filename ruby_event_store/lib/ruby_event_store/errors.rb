module RubyEventStore
  WrongExpectedEventVersion  = Class.new(StandardError)
  InvalidExpectedVersion     = Class.new(StandardError)
  IncorrectStreamData        = Class.new(StandardError)
  EventNotFound              = Class.new(StandardError)
  SubscriberNotExist         = Class.new(StandardError)
  InvalidPageStart           = Class.new(ArgumentError)
  InvalidPageSize            = Class.new(ArgumentError)

  class InvalidHandler < StandardError
    def initialize(subscriber)
      super("#call method not found in #{subscriber.class} subscriber. Are you sure it is a valid subscriber?")
    end
  end
end
