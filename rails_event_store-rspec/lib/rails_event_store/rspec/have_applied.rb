module RailsEventStore
  module RSpec
    class HaveApplied
      def initialize(*expected)
        raise ArgumentError if expected.empty?
        @expected = expected
        @matcher  = ::RSpec::Matchers::BuiltIn::Include.new(*@expected)
      end

      def matches?(aggregate_root)
        events = aggregate_root.__send__(:unpublished_events)
        @matcher.matches?(events) && matches_count(events, @expected, @count)
      end

      def exactly(count)
        @count = count
        self
      end

      def times
        self
      end
      alias :time :times

      def once
        exactly(1)
      end

      private

      def matches_count(events, expected, count)
        return true unless count
        raise NotSupported if expected.size > 1

        expected.all? do |event_or_matcher|
          events.select { |e| event_or_matcher === e }.size.equal?(count)
        end
      end
    end
  end
end

