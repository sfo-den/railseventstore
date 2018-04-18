module RubyEventStore
  module ROM
    module Repositories
      class Events < ::ROM::Repository[:events]
        class CreateEventsChangeset < ::ROM::Changeset::Create
          # Convert to Hash
          map(&:to_h)

          map do
            rename_keys event_id: :id
            accept_keys %i[id data metadata event_type]
          end
        end

        POSITION_SHIFT = 1.freeze

        # relations :stream_entries
        # commands :create
        # struct_namespace Entities
        # auto_struct false

        ### Writer interface

        def create(serialized_records)
          events.changeset(CreateEventsChangeset, serialized_records).commit
        end

        def link(event_ids, stream, expected_version = ExpectedVersion.any, global_stream: nil)
          (event_ids - events.by_pks(event_ids).pluck(:id)).each do |id|
            raise EventNotFound.new(id)
          end

          resolved_version = expected_version.resolve_for(stream, ->(stream) {
            (stream_entries.max_position(stream) || {})[:position]
          })

          tuples = []

          event_ids.each_with_index do |event_id, index|
            tuples << {
              stream: stream.name,
              position: compute_position(resolved_version, index),
              event_id: event_id
            } unless stream.global?

            tuples << {
              stream: GLOBAL_STREAM,
              event_id: event_id
            } if global_stream
          end

          stream_entries.changeset(:create, tuples).commit
        end

        ### Reader interface

        def exist?(event_id)
          events.by_pk(event_id).exist?
        end
  
        def by_id(event_id)
          events.map_with(:serialized_record_mapper).by_pk(event_id).one!
        end

        def read(direction, stream, from: :head, limit: nil)
          unless from.equal?(:head)
            offset_entry_id = stream_entries.by_stream_and_event_id(stream, from)[:id]
          end
          
          Mappers::SerializedRecord.new.call(
            stream_entries
              .ordered(direction, stream, offset_entry_id)
              .limit(limit)
              .combine(:event)
              .to_a
              .map(&:event)
          )

        rescue ::ROM::TupleCountMismatchError
          raise EventNotFound.new(from)
        end

        private

        def compute_position(version, offset)
          version + offset + POSITION_SHIFT if version
        end
      end
    end
  end
end
