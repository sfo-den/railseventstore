require 'active_record'

module RailsEventStore
  module Models
    class EventEntity < ActiveRecord::Base
      self.primary_key = :id
      self.table_name = 'event_store_events'
      serialize :metadata
      serialize :data
      validates_uniqueness_of :event_id
    end
  end
end