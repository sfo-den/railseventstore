require_relative 'migrator'
require_relative 'subprocess_helper'


module SchemaHelper
  include SubprocessHelper

  def run_migration(name)
    m = Migrator.new(File.expand_path('../rails_event_store_active_record/lib/rails_event_store_active_record/generators/templates', __dir__))
    m.run_migration(name)
  end

  def run_support_migration(name, template_name)
    m = Migrator.new(File.expand_path(__dir__))
    m.run_migration(name, template_name)
  end

  def establish_database_connection
    ActiveRecord::Base.establish_connection(ENV['DATABASE_URL'])
  end

  def close_database_connection
    ActiveRecord::Base.remove_connection
  end

  def load_database_schema
    run_migration('create_event_store_events')
  end

  def drop_database
    ActiveRecord::Migration.drop_table("event_store_events")
    ActiveRecord::Migration.drop_table("event_store_events_in_streams")
  rescue ActiveRecord::StatementInvalid
  end

  def load_legacy_database_schema
    run_support_migration('create_event_store_events', '0_18_2_migration')
  end

  def drop_legacy_database
    ActiveRecord::Migration.drop_table("event_store_events")
  rescue ActiveRecord::StatementInvalid
  end

  def dump_schema
    schema = StringIO.new
    ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, schema)
    schema.rewind
    schema.read
  end

  def build_schema(gemfile)
    run_in_subprocess(<<~EOF, gemfile: gemfile)
      require 'rails/generators'
      require 'rails_event_store_active_record'
      require 'ruby_event_store'
      require 'logger'
      require '../lib/migrator'

      $verbose = ENV.has_key?('VERBOSE') ? true : false
      ActiveRecord::Schema.verbose = $verbose
      ActiveRecord::Base.logger    = Logger.new(STDOUT) if $verbose
      ActiveRecord::Base.establish_connection(ENV['DATABASE_URL'])

      gem_path = $LOAD_PATH.find { |path| path.match(/rails_event_store_active_record/) }
      Migrator.new(File.expand_path('rails_event_store_active_record/generators/templates', gem_path))
        .run_migration('create_event_store_events', 'migration')
    EOF
  end
end
