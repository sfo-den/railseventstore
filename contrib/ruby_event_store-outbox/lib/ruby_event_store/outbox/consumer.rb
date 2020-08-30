require "logger"
require "redis"
require "active_record"
require "ruby_event_store/outbox/record"
require "ruby_event_store/outbox/sidekiq5_format"

module RubyEventStore
  module Outbox
    class Consumer
      SLEEP_TIME_WHEN_NOTHING_TO_DO = 0.1

      class Configuration
        def initialize(
          split_keys:,
          message_format:,
          batch_size:,
          database_url:,
          redis_url:
        )
          @split_keys = split_keys
          @message_format = message_format
          @batch_size = batch_size || 100
          @database_url = database_url
          @redis_url = redis_url
          freeze
        end

        def with(overriden_options)
          self.class.new(
            split_keys: overriden_options.fetch(:split_keys, split_keys),
            message_format: overriden_options.fetch(:message_format, message_format),
            batch_size: overriden_options.fetch(:batch_size, batch_size),
            database_url: overriden_options.fetch(:database_url, database_url),
            redis_url: overriden_options.fetch(:redis_url, redis_url),
          )
        end

        attr_reader :split_keys, :message_format, :batch_size, :database_url, :redis_url
      end

      def initialize(configuration, clock: Time, logger:, metrics:)
        @split_keys = configuration.split_keys
        @clock = clock
        @redis = Redis.new(url: configuration.redis_url)
        @logger = logger
        @metrics = metrics
        @batch_size = configuration.batch_size
        ActiveRecord::Base.establish_connection(configuration.database_url) unless ActiveRecord::Base.connected?
        if ActiveRecord::Base.connection.adapter_name == "Mysql2"
          ActiveRecord::Base.connection.execute("SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;")
          ActiveRecord::Base.connection.execute("SET SESSION innodb_lock_wait_timeout = 1;")
        end

        raise "Unknown format" if configuration.message_format != SIDEKIQ5_FORMAT
        @message_format = SIDEKIQ5_FORMAT

        @gracefully_shutting_down = false
        prepare_traps
      end

      def init
        @redis.sadd("queues", split_keys)
        logger.info("Initiated RubyEventStore::Outbox v#{VERSION}")
        logger.info("Handling split keys: #{split_keys ? split_keys.join(", ") : "(all of them)"}")
      end

      def run
        while !@gracefully_shutting_down do
          was_something_changed = one_loop
          if !was_something_changed
            STDOUT.flush
            sleep SLEEP_TIME_WHEN_NOTHING_TO_DO
          end
        end
        logger.info "Gracefully shutting down"
      end

      def one_loop
        Record.transaction do
          records_scope = Record.lock.where(format: message_format, enqueued_at: nil)
          records_scope = records_scope.where(split_key: split_keys) if !split_keys.nil?
          records = records_scope.order("id ASC").limit(batch_size).to_a
          if records.empty?
            metrics.write_point_queue(status: "ok")
            return false
          end

          now = @clock.now.utc
          failed_record_ids = []
          parsed_records = []
          records.each do |record|
            begin
              parsed_records << JSON.parse(record.payload).merge({
                "enqueued_at" => now.to_f,
              })
            rescue => e
              failed_record_ids << record.id
              e.full_message.split($/).each {|line| logger.error(line) }
            end
          end
          parsed_records.group_by do |parsed_record|
            parsed_record["queue"]
          end.each do |queue, records_for_queue|
            if queue.nil?
              failed.concat(records_for_queue.map(&:id))
            else
              begin
                @redis.lpush("queue:#{queue}", records_for_queue.map {|r| JSON.generate(r) })
              rescue => e
                failed_record_ids.concat(records2.map(&:id))
                e.full_message.split($/).each {|line| logger.error(line) }
              end
            end
          end

          updated_record_ids = records.map(&:id) - failed_record_ids
          Record.where(id: updated_record_ids).update_all(enqueued_at: now)
          metrics.write_point_queue(status: "ok", enqueued: updated_record_ids.size, failed: failed_record_ids.size)

          logger.info "Sent #{updated_record_ids.size} messages from outbox table"
          true
        end
      rescue ActiveRecord::Deadlocked
        logger.warn "Outbox fetch deadlocked"
        metrics.write_point_queue(status: "deadlocked")
        false
      rescue ActiveRecord::LockWaitTimeout
        logger.warn "Outbox fetch lock timeout"
        metrics.write_point_queue(status: "lock_timeout")
        false
      end

      private
      attr_reader :split_keys, :logger, :message_format, :batch_size, :metrics

      def prepare_traps
        Signal.trap("INT") do
          initiate_graceful_shutdown
        end
        Signal.trap("TERM") do
          initiate_graceful_shutdown
        end
      end

      def initiate_graceful_shutdown
        @gracefully_shutting_down = true
      end
    end
  end
end
