require "spec_helper"

module RailsEventStore
  module RSpec
    ::RSpec.describe HaveApplied do
      let(:matchers) { Object.new.tap { |o| o.extend(Matchers) } }
      let(:aggregate_root) { TestAggregate.new }

      def matcher(*expected)
        HaveApplied.new(*expected)
      end

      specify do
        aggregate_root.foo
        expect(aggregate_root).to matcher(matchers.an_event(FooEvent))
      end

      specify do
        aggregate_root.foo
        expect(aggregate_root).not_to matcher(matchers.an_event(BazEvent))
      end

      specify do
        aggregate_root.foo
        aggregate_root.foo
        expect(aggregate_root).not_to matcher(matchers.an_event(FooEvent)).exactly(1)
      end

      specify do
        aggregate_root.foo
        aggregate_root.foo
        expect(aggregate_root).to matcher(matchers.an_event(FooEvent)).exactly(2)
      end

      specify do
        aggregate_root.foo
        aggregate_root.bar
        expect(aggregate_root).to matcher(matchers.an_event(FooEvent)).exactly(1)
      end

      specify do
        aggregate_root.foo
        aggregate_root.foo
        expect(aggregate_root).to matcher(matchers.an_event(FooEvent)).exactly(2).times
      end

      specify do
        aggregate_root.foo
        expect(aggregate_root).to matcher(matchers.an_event(FooEvent)).exactly(1).time
      end

      specify do
        aggregate_root.foo
        expect(aggregate_root).to matcher(matchers.an_event(FooEvent)).once
      end

      specify do
        aggregate_root.foo
        aggregate_root.foo
        expect(aggregate_root).not_to matcher(matchers.an_event(FooEvent)).once
      end

      specify do
        aggregate_root.foo
        aggregate_root.bar

        expect(aggregate_root).to matcher(
          matchers.an_event(FooEvent),
          matchers.an_event(BarEvent)
        )
      end

      specify do
        aggregate_root.foo

        expect(aggregate_root).not_to matcher(
          matchers.an_event(FooEvent),
          matchers.an_event(BazEvent)
        )
      end

      specify do
        aggregate_root.foo
        aggregate_root.bar

        expect(aggregate_root).not_to matcher(
          matchers.an_event(FooEvent),
          matchers.an_event(BazEvent)
        )
      end

      specify do
        aggregate_root.foo
        aggregate_root.bar

        expect{
          expect(aggregate_root).to matcher(
            matchers.an_event(FooEvent),
            matchers.an_event(BarEvent)
          ).exactly(2).times
        }.to raise_error(NotSupported)
      end

      specify { expect{ HaveApplied.new() }.to raise_error(ArgumentError) }
    end
  end
end
