require "logger"
require "redis"
require "active_record"
require "ruby_event_store/outbox/record"
require "ruby_event_store/outbox/sidekiq_scheduler"

module RubyEventStore
  module Outbox
    class Consumer
      SLEEP_TIME_WHEN_NOTHING_TO_DO = 0.1

      def initialize(format, split_keys, database_url:, redis_url:, clock: Time, logger:)
        @split_keys = split_keys
        @clock = clock
        @redis = Redis.new(url: redis_url)
        @logger = logger
        ActiveRecord::Base.establish_connection(database_url)

        raise "Unknown format" if format != SidekiqScheduler::SIDEKIQ5_FORMAT
        @message_format = SidekiqScheduler::SIDEKIQ5_FORMAT
      end

      def init
        @redis.sadd("queues", split_keys)
        logger.info("Initiated RubyEventStore::Outbox v#{VERSION}")
        logger.info("Handling split keys: #{split_keys ? split_keys.join(", ") : "(all of them)"}")
      end

      def run
        loop do
          was_something_changed = one_loop
          sleep SLEEP_TIME_WHEN_NOTHING_TO_DO if !was_something_changed
        end
      end

      def one_loop
        Record.transaction do
          records_scope = Record.lock.where(format: message_format, enqueued_at: nil)
          records_scope = records_scope.where(split_key: split_keys) if !split_keys.nil?
          records = records_scope.order("id ASC").limit(100)
          return false if records.empty?

          now = @clock.now.utc
          records.each do |record|
            hash_payload = JSON.parse(record.payload)
            @redis.lpush("queue:#{hash_payload.fetch("queue")}", JSON.generate(JSON.parse(record.payload).merge({
              "enqueued_at" => now.to_f,
            })))
          end

          records.update_all(enqueued_at: now)
          logger.info "Sent #{records.size} messages from outbox table"
          return true
        end
      end

      private
      attr_reader :split_keys, :logger, :message_format
    end
  end
end
