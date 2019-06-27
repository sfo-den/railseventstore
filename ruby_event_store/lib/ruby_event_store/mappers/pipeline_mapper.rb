# frozen_string_literal: true

module RubyEventStore
  module Mappers
    class PipelineMapper
      def initialize(pipeline)
        @pipeline = pipeline
      end

      def event_to_serialized_record(domain_event)
        pipeline.dump(domain_event)
      end

      def serialized_record_to_event(record)
        pipeline.load(record)
      end

      private
      attr_reader :pipeline
    end
  end
end
