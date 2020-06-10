require 'spec_helper'
require_relative './support/sidekiq'

module RubyEventStore
  module Outbox
    RSpec.describe "Sidekiq integration spec" do
      include SchemaHelper
      let(:redis_url) { ENV["REDIS_URL"] }
      let(:database_url) { ENV["DATABASE_URL"] }
      let(:redis) { Redis.new(url: redis_url) }
      let(:test_logger) { Logger.new(StringIO.new) }

      around(:each) do |example|
        begin
          establish_database_connection
          # load_database_schema
          m = Migrator.new(File.expand_path('../lib/generators/ruby_event_store/outbox/templates', __dir__))
          m.run_migration('create_event_store_outbox')
          example.run
        ensure
          # drop_database
          begin
            ActiveRecord::Migration.drop_table("event_store_outbox")
          rescue ActiveRecord::StatementInvalid
          end
        end
      end

      before(:each) do |example|
        Sidekiq.configure_client do |config|
          config.redis = { url: redis_url }
        end
        reset_sidekiq_middlewares
        redis.flushdb
      end

      specify do
        event = TimestampEnrichment.with_timestamp(Event.new(event_id: "83c3187f-84f6-4da7-8206-73af5aca7cc8"), Time.utc(2019, 9, 30))
        serialized_event = RubyEventStore::Mappers::Default.new.event_to_serialized_record(event)
        class ::CorrectAsyncHandler
          include Sidekiq::Worker
          def through_outbox?; true; end
        end

        SidekiqScheduler.new.call(CorrectAsyncHandler, serialized_event)
        consumer = Consumer.new(["default"], database_url: database_url, redis_url: redis_url, logger: test_logger)
        consumer.one_loop
        entry_from_outbox = JSON.parse(redis.lindex("queue:default", 0))

        CorrectAsyncHandler.perform_async(serialized_event.to_h)
        entry_from_sidekiq = JSON.parse(redis.lindex("queue:default", 0))

        expect(redis.llen("queue:default")).to eq(2)
        expect(entry_from_outbox.keys).to eq(entry_from_sidekiq.keys)
        expect(entry_from_outbox.except("created_at", "enqueued_at", "jid")).to eq(entry_from_sidekiq.except("created_at", "enqueued_at", "jid"))
        expect(entry_from_outbox.fetch("jid")).not_to eq(entry_from_sidekiq.fetch("jid"))
      end
    end
  end
end
