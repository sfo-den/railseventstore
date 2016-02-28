module RailsEventStore
  module Repositories
    class EventRepository

      def initialize
        @adapter = ::RailsEventStore::Models::Event
      end
      attr_reader :adapter

      def create(event, stream_name)
        data = event.to_h.merge!(stream: stream_name)
        build_event_entity(adapter.create(data))
      end

      def delete_stream(stream_name)
        condition = {stream: stream_name}
        adapter.destroy_all condition
        nil
      end

      def has_event?(event_id)
        adapter.exists?(event_id: event_id)
      end

      def last_stream_event(stream_name)
        build_event_entity(adapter.where(stream: stream_name).last)
      end

      def get_all_events
        adapter.order('id ASC').order('stream').all.map(&method(:build_event_entity))
      end

      def read_events_forward(stream_name, start_event_id, count)
        stream = adapter.where(stream: stream_name)
        if start_event_id
          starting_event = adapter.find_by(event_id: start_event_id)
          stream = stream.where('id > ?', starting_event.id)
        end

        stream.order('id ASC').limit(count)
          .map(&method(:build_event_entity))
      end

      def read_events_backward(stream_name, start_event_id, count)
        stream = adapter.where(stream: stream_name)
        if start_event_id
          starting_event = adapter.find_by(event_id: start_event_id)
          stream = stream.where('id < ?', starting_event.id)
        end

        stream.order('id DESC').limit(count)
          .map(&method(:build_event_entity))
      end

      def read_stream_events_forward(stream_name)
        adapter.where(stream: stream_name).order('id ASC')
          .map(&method(:build_event_entity))
      end

      def read_stream_events_backward(stream_name)
        adapter.where(stream: stream_name).order('id DESC')
          .map(&method(:build_event_entity))
      end

      def read_all_streams_forward(start_event_id, count)
        stream = adapter
        if start_event_id
          starting_event = adapter.find_by(event_id: start_event_id)
          stream = stream.where('id > ?', starting_event.id)
        end

        stream.order('id ASC').limit(count)
          .map(&method(:build_event_entity))
      end

      def read_all_streams_backward(start_event_id, count)
        stream = adapter
        if start_event_id
          starting_event = adapter.find_by(event_id: start_event_id)
          stream = stream.where('id < ?', starting_event.id)
        end

        stream.order('id DESC').limit(count)
          .map(&method(:build_event_entity))
      end

      private

      def build_event_entity(record)
        return nil unless record
        ::RailsEventStore::Event.new(record.data.merge(
          event_type: record.event_type,
          event_id:   record.event_id,
          metadata:   record.metadata))
      end

    end
  end
end
