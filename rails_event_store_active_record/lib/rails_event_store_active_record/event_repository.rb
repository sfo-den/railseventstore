# frozen_string_literal: true

require 'activerecord-import'

module RailsEventStoreActiveRecord
  class EventRepository
    POSITION_SHIFT = 1
    SERIALIZED_GLOBAL_STREAM_NAME = "all".freeze

    def initialize(serializer: YAML)
      @repo_reader = EventRepositoryReader.new(serializer)
      @serializer  = serializer
    end

    def append_to_stream(records, stream, expected_version)
      hashes, event_ids = [], []
      serialized_records = Array(records).map{|record| record.serialize(serializer)}
      serialized_records.each do |serialized_record|
        hashes << serialized_record_hash(serialized_record)
        event_ids << serialized_record.event_id
      end
      add_to_stream(event_ids, stream, expected_version, true) do
        Event.import(hashes)
      end
    end

    def link_to_stream(event_ids, stream, expected_version)
      event_ids = Array(event_ids)
      (event_ids - Event.where(id: event_ids).pluck(:id)).each do |id|
        raise RubyEventStore::EventNotFound.new(id)
      end
      add_to_stream(event_ids, stream, expected_version, nil)
    end

    def delete_stream(stream)
      EventInStream.where(stream: stream.name).delete_all
    end

    def has_event?(event_id)
      @repo_reader.has_event?(event_id)
    end

    def last_stream_event(stream)
      @repo_reader.last_stream_event(stream)
    end

    def read(specification)
      @repo_reader.read(specification)
    end

    def count(specification)
      @repo_reader.count(specification)
    end

    def update_messages(records)
      hashes  = Array(records).map{|record| serialized_record_hash(record.serialize(serializer)) }
      for_update = records.map(&:event_id)
      start_transaction do
        existing = Event.where(id: for_update).pluck(:id)
        (for_update - existing).each{|id| raise RubyEventStore::EventNotFound.new(id) }
        Event.import(hashes, on_duplicate_key_update: [:data, :metadata, :event_type])
      end
    end

    def streams_of(event_id)
      EventInStream.where(event_id: event_id)
        .where.not(stream: SERIALIZED_GLOBAL_STREAM_NAME)
        .pluck(:stream)
        .map{|name| RubyEventStore::Stream.new(name)}
    end

    private
    attr_reader :serializer

    def add_to_stream(event_ids, stream, expected_version, include_global)
      last_stream_version = ->(stream_) { EventInStream.where(stream: stream_.name).order("position DESC").first.try(:position) }
      resolved_version = expected_version.resolve_for(stream, last_stream_version)

      start_transaction do
        yield if block_given?
        in_stream = event_ids.flat_map.with_index do |event_id, index|
          position = compute_position(resolved_version, index)
          collection = []
          collection.unshift({
            stream: SERIALIZED_GLOBAL_STREAM_NAME,
            position: nil,
            event_id: event_id,
          }) if include_global
          collection.unshift({
            stream:   stream.name,
            position: position,
            event_id: event_id
          }) unless stream.global?
          collection
        end
        fill_ids(in_stream)
        EventInStream.import(in_stream)
      end
      self
    rescue ActiveRecord::RecordNotUnique => e
      raise_error(e)
    end

    def raise_error(e)
      if detect_index_violated(e.message)
        raise RubyEventStore::EventDuplicatedInStream
      end
      raise RubyEventStore::WrongExpectedEventVersion
    end

    def compute_position(resolved_version, index)
      unless resolved_version.nil?
        resolved_version + index + POSITION_SHIFT
      end
    end

    def detect_index_violated(message)
      IndexViolationDetector.new.detect(message)
    end

    def serialized_record_hash(serialized_record)
      {
        id:         serialized_record.event_id,
        data:       serialized_record.data,
        metadata:   serialized_record.metadata,
        event_type: serialized_record.event_type
      }
    end

    # Overwritten in a sub-class
    def fill_ids(_in_stream)
    end

    def start_transaction(&block)
      ActiveRecord::Base.transaction(requires_new: true, &block)
    end
  end

end
