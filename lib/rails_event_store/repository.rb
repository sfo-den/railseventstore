require 'active_support/core_ext/class/attribute_accessors'

module RailsEventStore
  class Repository
    cattr_reader :adapter

    def self.adapter=(adapter)
      case adapter
      when String, Symbol
        @@adapter = "::RailsEventStore#{adapter.to_s.classify}::EventRepository".constantize.new
      else
        @@adapter = adapter
      end
    end
  end
end
