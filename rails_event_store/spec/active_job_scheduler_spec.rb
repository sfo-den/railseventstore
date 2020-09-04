require 'spec_helper'
require 'ruby_event_store/spec/scheduler_lint'

module RailsEventStore
  RSpec.describe ActiveJobScheduler do
    around do |example|
      begin
        original_logger = ActiveJob::Base.logger
        ActiveJob::Base.logger = nil

        original_adapter = ActiveJob::Base.queue_adapter
        ActiveJob::Base.queue_adapter = :test

        example.run
      ensure
        ActiveJob::Base.logger = original_logger
        ActiveJob::Base.queue_adapter = original_adapter
      end
    end

    before(:each) do
      MyAsyncHandler.reset
    end

    it_behaves_like :scheduler, ActiveJobScheduler.new

    let(:event) { TimestampEnrichment.with_timestamp(Event.new(event_id: "83c3187f-84f6-4da7-8206-73af5aca7cc8"), Time.utc(2019, 9, 30)) }
    let(:serialized_record) { RubyEventStore::Mappers::Default.new.event_to_serialized_record(event) }

    describe "#verify" do
      specify do
        scheduler = ActiveJobScheduler.new
        proper_handler = Class.new(ActiveJob::Base)
        expect(scheduler.verify(proper_handler)).to eq(true)
      end

      specify do
        scheduler = ActiveJobScheduler.new
        some_class = Class.new
        expect(scheduler.verify(some_class)).to eq(false)
      end

      specify do
        scheduler = ActiveJobScheduler.new
        expect(scheduler.verify(ActiveJob::Base)).to eq(false)
      end

      specify do
        scheduler = ActiveJobScheduler.new
        expect(scheduler.verify(Object.new)).to eq(false)
      end
    end

    describe "#call" do
      specify do
        scheduler = ActiveJobScheduler.new
        scheduler.call(MyAsyncHandler, serialized_record)

        enqueued_jobs = ActiveJob::Base.queue_adapter.enqueued_jobs
        expect(enqueued_jobs.size).to eq(1)
        expect(enqueued_jobs[0]).to include(
          {
            job: MyAsyncHandler,
            args: [
              {
                "event_id"        => "83c3187f-84f6-4da7-8206-73af5aca7cc8",
                "event_type"      => "RubyEventStore::Event",
                "data"            => "--- {}\n",
                "metadata"        => "---\n:timestamp: 2019-09-30 00:00:00.000000000 Z\n",
                "_aj_symbol_keys" => %w[event_id data metadata event_type],
              },
            ],
            queue: "default",
          },
        )
      end
    end

    class MyAsyncHandler < ActiveJob::Base
      @@received = nil
      def self.reset
        @@received = nil
      end
      def self.received
        @@received
      end
      def perform(event)
        @@received = event
      end
    end
  end
end
