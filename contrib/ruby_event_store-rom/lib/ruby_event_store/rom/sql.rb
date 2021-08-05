# frozen_string_literal: true

module RubyEventStore
  module ROM
    module SQL
      class << self
        def setup(config)
          config.register_mapper(Mappers::StreamEntryToSerializedRecord)
          config.register_mapper(Mappers::EventToSerializedRecord)
          config.register_relation Relations::Events
          config.register_relation Relations::StreamEntries
        end

        def configure(env)
          # See: https://github.com/jeremyevans/sequel/blob/master/doc/transactions.rdoc
          env.register_unit_of_work_options(
            savepoint: true,
            # Committing changesets concurrently causes MySQL deadlocks
            # which are not caught and retried by Sequel's built-in
            # :retry_on option. This appears to be a result of how ROM
            # handles exceptions which don't bubble up so that Sequel
            # can retry transactions with the :retry_on option when there's
            # a deadlock.
            #
            # This is exacerbated by the fact that changesets insert multiple
            # tuples with individual INSERT statements because ROM specifies
            # to Sequel to return a list of primary keys created. The likelihood
            # of a deadlock is reduced with batched INSERT statements.
            #
            # For this reason we need to manually insert changeset records to avoid
            # MySQL deadlocks or to allow Sequel to retry transactions
            # when the :retry_on option is specified.
            retry_on: Sequel::SerializationFailure,
            before_retry: lambda { |_num, ex|
              env.logger.warn("RETRY TRANSACTION [#{self.class.name} => #{ex.class.name}] #{ex.message}")
            }
          )
        end

        def supports_upsert?(db)
          supports_on_duplicate_key_update?(db) ||
            supports_insert_conflict_update?(db)
        end

        def supports_on_duplicate_key_update?(db)
          db.adapter_scheme =~ /mysql/
        end

        def supports_insert_conflict_update?(db)
          case db.adapter_scheme
          when :postgres
            true
          when :sqlite
            # Sqlite 3.24.0+ supports PostgreSQL upsert syntax
            db.sqlite_version >= 32_400
          else
            false
          end
        end
      end
    end
  end
end
