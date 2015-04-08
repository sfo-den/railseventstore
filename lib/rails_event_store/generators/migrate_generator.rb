require 'rails/generators'

module RailsEventStore
  class MigrateGenerator < Rails::Generators::Base
    source_root File.expand_path(File.join(File.dirname(__FILE__), '../generators/templates'))

    def create_migration
      template "migration_template.rb", "db/migrate/#{timestamp}_create_events_table.rb"
    end

    private

    def timestamp
      Time.now.strftime("%Y%m%d%H%M%S")
    end

  end
end
