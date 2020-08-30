require 'spec_helper'

module RubyEventStore
  module Outbox
    RSpec.describe Consumer, db: true do
      include SchemaHelper

      let(:redis_url) { ENV["REDIS_URL"] }
      let(:database_url) { ENV["DATABASE_URL"] }
      let(:redis) { Redis.new(url: redis_url) }
      let(:logger_output) { StringIO.new }
      let(:logger) { Logger.new(logger_output) }
      let(:default_configuration) { Consumer::Configuration.new(database_url: database_url, redis_url: redis_url, split_keys: ["default", "default2"], message_format: SIDEKIQ5_FORMAT, batch_size: 100) }
      let(:metrics) { Metrics::Null.new }

      before(:each) do
        redis.flushdb
      end

      specify "updates enqueued_at" do
        payload = {
          class: "SomeAsyncHandler",
          queue: "default",
          created_at: Time.now.utc,
          jid: SecureRandom.hex(12),
          retry: true,
          args: [{
            event_id: "83c3187f-84f6-4da7-8206-73af5aca7cc8",
            event_type: "RubyEventStore::Event",
            data: "--- {}\n",
            metadata: "---\n:timestamp: 2019-09-30 00:00:00.000000000 Z\n",
          }],
        }
        record = Record.create!(
          split_key: "default",
          created_at: Time.now.utc,
          format: "sidekiq5",
          enqueued_at: nil,
          payload: payload.to_json
        )
        consumer = Consumer.new(default_configuration, logger: logger, metrics: metrics)

        consumer.one_loop

        record.reload
        expect(record.enqueued_at).to be_present
      end

      specify "push the jobs to sidekiq" do
        payload = {
          class: "SomeAsyncHandler",
          queue: "default",
          created_at: Time.now.utc,
          jid: SecureRandom.hex(12),
          retry: true,
          args: [{
            event_id: "83c3187f-84f6-4da7-8206-73af5aca7cc8",
            event_type: "RubyEventStore::Event",
            data: "--- {}\n",
            metadata: "---\n:timestamp: 2019-09-30 00:00:00.000000000 Z\n",
          }],
        }
        record = Record.create!(
          split_key: "default",
          created_at: Time.now.utc,
          format: "sidekiq5",
          enqueued_at: nil,
          payload: payload.to_json
        )
        clock = TickingClock.new
        consumer = Consumer.new(default_configuration, clock: clock, logger: logger, metrics: metrics)
        result = consumer.one_loop

        expect(redis.llen("queue:default")).to eq(1)
        payload_in_redis = JSON.parse(redis.lindex("queue:default", 0))
        expect(payload_in_redis).to include(payload.as_json)
        expect(payload_in_redis["enqueued_at"]).to eq(clock.tick(1).to_f)
        record.reload
        expect(record.enqueued_at).to eq(clock.tick(1))
        expect(result).to eq(true)
        expect(logger_output.string).to include("Sent 1 messages from outbox table")
      end

      specify "push multiple jobs to different queues" do
        payload1 = {
          class: "SomeAsyncHandler",
          queue: "default",
          created_at: Time.now.utc,
          jid: SecureRandom.hex(12),
          retry: true,
          args: [{
            event_id: "83c3187f-84f6-4da7-8206-73af5aca7cc8",
            event_type: "RubyEventStore::Event",
            data: "--- {}\n",
            metadata: "---\n:timestamp: 2019-09-30 00:00:00.000000000 Z\n",
          }],
        }
        payload2 = payload1.merge("queue" => "default2")
        record1 = Record.create!(
          split_key: "default",
          created_at: Time.now.utc,
          format: "sidekiq5",
          enqueued_at: nil,
          payload: payload1.to_json
        )
        record2 = Record.create!(
          split_key: "default",
          created_at: Time.now.utc,
          format: "sidekiq5",
          enqueued_at: nil,
          payload: payload1.to_json
        )
        record3 = Record.create!(
          split_key: "default2",
          created_at: Time.now.utc,
          format: "sidekiq5",
          enqueued_at: nil,
          payload: payload2.merge(queue: "default2").to_json
        )
        clock = TickingClock.new
        consumer = Consumer.new(default_configuration, clock: clock, logger: logger, metrics: metrics)
        result = consumer.one_loop

        expect(redis.llen("queue:default")).to eq(2)
        expect(redis.llen("queue:default2")).to eq(1)
      end

      specify "initiating consumer ensures that queues exist" do
        consumer = Consumer.new(default_configuration, logger: logger, metrics: metrics)

        consumer.init

        expect(redis.scard("queues")).to eq(2)
        expect(redis.smembers("queues")).to match_array(["default", "default2"])
        expect(logger_output.string).to include("Initiated RubyEventStore::Outbox v#{RubyEventStore::Outbox::VERSION}")
      end

      specify "returns false if no records" do
        consumer = Consumer.new(default_configuration, logger: logger, metrics: metrics)

        result = consumer.one_loop

        expect(result).to eq(false)
      end

      specify "returns false if didnt aquire lock" do
        payload = {
          class: "SomeAsyncHandler",
          queue: "default",
          created_at: Time.now.utc,
          jid: SecureRandom.hex(12),
          retry: true,
          args: [{
            event_id: "83c3187f-84f6-4da7-8206-73af5aca7cc8",
            event_type: "RubyEventStore::Event",
            data: "--- {}\n",
            metadata: "---\n:timestamp: 2019-09-30 00:00:00.000000000 Z\n",
          }],
        }
        record = Record.create!(
          split_key: "default",
          format: "sidekiq5",
          enqueued_at: nil,
          payload: payload.to_json
        )
        consumer = Consumer.new(default_configuration, logger: logger, metrics: metrics)
        clock = TickingClock.new
        Lock.obtain("default", "some-other-process-uuid", clock: clock)

        result = consumer.one_loop

        expect(result).to eq(false)
        expect(redis.llen("queue:default")).to eq(0)
      end

      specify "already processed should be ignored" do
        payload = {
          class: "SomeAsyncHandler",
          queue: "default",
          created_at: Time.now.utc,
          jid: SecureRandom.hex(12),
          retry: true,
          args: [{
            event_id: "83c3187f-84f6-4da7-8206-73af5aca7cc8",
            event_type: "RubyEventStore::Event",
            data: "--- {}\n",
            metadata: "---\n:timestamp: 2019-09-30 00:00:00.000000000 Z\n",
          }],
        }
        record = Record.create!(
          split_key: "default",
          created_at: Time.now.utc,
          format: "sidekiq5",
          enqueued_at: Time.now.utc,
          payload: payload.to_json,
        )
        consumer = Consumer.new(default_configuration, logger: logger, metrics: metrics)
        result = consumer.one_loop

        expect(result).to eq(false)
        expect(redis.llen("queue:default")).to eq(0)
        expect(logger_output.string).to be_empty
      end

      specify "other format should be ignored" do
        payload = {
          class: "SomeAsyncHandler",
          queue: "default",
          created_at: Time.now.utc,
          jid: SecureRandom.hex(12),
          retry: true,
          args: [{
            event_id: "83c3187f-84f6-4da7-8206-73af5aca7cc8",
            event_type: "RubyEventStore::Event",
            data: "--- {}\n",
            metadata: "---\n:timestamp: 2019-09-30 00:00:00.000000000 Z\n",
          }],
        }
        record = Record.create!(
          split_key: "default",
          created_at: Time.now.utc,
          format: "something_unknown",
          enqueued_at: nil,
          payload: payload.to_json,
        )
        consumer = Consumer.new(default_configuration, logger: logger, metrics: metrics)
        result = consumer.one_loop

        expect(result).to eq(false)
        expect(redis.llen("queue:default")).to eq(0)
        expect(logger_output.string).to be_empty
      end

      specify "records from other split keys should be ignored" do
        payload = {
          class: "SomeAsyncHandler",
          queue: "other_one",
          created_at: Time.now.utc,
          jid: SecureRandom.hex(12),
          retry: true,
          args: [{
            event_id: "83c3187f-84f6-4da7-8206-73af5aca7cc8",
            event_type: "RubyEventStore::Event",
            data: "--- {}\n",
            metadata: "---\n:timestamp: 2019-09-30 00:00:00.000000000 Z\n",
          }],
        }
        record = Record.create!(
          split_key: "other_one",
          created_at: Time.now.utc,
          format: "sidekiq5",
          enqueued_at: nil,
          payload: payload.to_json,
        )
        consumer = Consumer.new(default_configuration, logger: logger, metrics: metrics)
        result = consumer.one_loop

        expect(result).to eq(false)
        expect(redis.llen("queue:other_one")).to eq(0)
        expect(logger_output.string).to be_empty
      end

      xspecify "all split keys should be taken if split_keys is nil" do
        payload = {
          class: "SomeAsyncHandler",
          queue: "default",
          created_at: Time.now.utc,
          jid: SecureRandom.hex(12),
          retry: true,
          args: [{
            event_id: "83c3187f-84f6-4da7-8206-73af5aca7cc8",
            event_type: "RubyEventStore::Event",
            data: "--- {}\n",
            metadata: "---\n:timestamp: 2019-09-30 00:00:00.000000000 Z\n",
          }],
        }
        record = Record.create!(
          split_key: "default",
          created_at: Time.now.utc,
          format: "sidekiq5",
          enqueued_at: nil,
          payload: payload.to_json,
        )
        consumer = Consumer.new(default_configuration.with(split_keys: nil), logger: logger, metrics: metrics)

        result = consumer.one_loop

        expect(result).to eq(true)
        expect(redis.llen("queue:default")).to eq(1)
      end

      specify "#run wait if nothing was changed" do
        consumer = Consumer.new(default_configuration, logger: logger, metrics: metrics)
        expect(consumer).to receive(:one_loop).and_return(false).ordered
        expect(consumer).to receive(:one_loop).and_raise("End infinite loop").ordered
        allow(consumer).to receive(:sleep)

        expect do
          consumer.run
        end.to raise_error("End infinite loop")

        expect(consumer).to have_received(:sleep).with(0.1)
      end

      specify "#run doesnt wait if something changed" do
        consumer = Consumer.new(default_configuration, logger: logger, metrics: metrics)
        expect(consumer).to receive(:one_loop).and_return(true).ordered
        expect(consumer).to receive(:one_loop).and_raise("End infinite loop").ordered
        allow(consumer).to receive(:sleep)

        expect do
          consumer.run
        end.to raise_error("End infinite loop")

        expect(consumer).not_to have_received(:sleep)
      end

      specify "incorrect payload wont cause later messages to schedule" do
        payload = {
          class: "SomeAsyncHandler",
          queue: "default",
          created_at: Time.now.utc,
          jid: SecureRandom.hex(12),
          retry: true,
          args: [{
            event_id: "83c3187f-84f6-4da7-8206-73af5aca7cc8",
            event_type: "RubyEventStore::Event",
            data: "--- {}\n",
            metadata: "---\n:timestamp: 2019-09-30 00:00:00.000000000 Z\n",
          }],
        }
        record1 = Record.create!(
          split_key: "default",
          created_at: Time.now.utc,
          format: "sidekiq5",
          enqueued_at: nil,
          payload: "unparsable garbage",
        )
        record2 = Record.create!(
          split_key: "default",
          created_at: Time.now.utc,
          format: "sidekiq5",
          enqueued_at: nil,
          payload: payload.to_json
        )
        clock = TickingClock.new
        consumer = Consumer.new(default_configuration, clock: clock, logger: logger, metrics: metrics)

        result = consumer.one_loop

        expect(result).to eq(true)
        expect(record1.reload.enqueued_at).to be_nil
        expect(record2.reload.enqueued_at).to be_present
        expect(redis.llen("queue:default")).to eq(1)
        expect(logger_output.string).to include("JSON::ParserError")
      end

      xspecify "deadlock cause us only to sleep" do
        expect(Record).to receive(:lock).and_raise(ActiveRecord::Deadlocked)
        clock = TickingClock.new
        consumer = Consumer.new(default_configuration, clock: clock, logger: logger, metrics: metrics)

        result = consumer.one_loop

        expect(logger_output.string).to include("Outbox fetch deadlocked")
        expect(result).to eq(false)
      end

      xspecify "lock timeout cause us only to sleep" do
        expect(Record).to receive(:lock).and_raise(ActiveRecord::LockWaitTimeout)
        consumer = Consumer.new(default_configuration, logger: logger, metrics: metrics)

        result = consumer.one_loop

        expect(logger_output.string).to include("Outbox fetch lock timeout")
        expect(result).to eq(false)
      end
    end
  end
end
