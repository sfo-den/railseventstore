# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  module ActiveRecord
    ::RSpec.describe TemplateDirectory do
      specify "returns template directory for postgresql adapter" do
        expect(TemplateDirectory.for_adapter(DatabaseAdapter.from_string("PostgreSQL"))).to eq("postgres/")
        expect(TemplateDirectory.for_adapter(DatabaseAdapter.from_string("PostGIS"))).to eq("postgres/")
      end

      specify "returns template directory for mysql2 adapter" do
        expect(TemplateDirectory.for_adapter(DatabaseAdapter.from_string("MySQL2"))).to eq("mysql/")
      end

      specify "returns template directory for sqlite adapter" do
        expect(TemplateDirectory.for_adapter(DatabaseAdapter.from_string("sqlite"))).to eq(nil)
      end
    end
  end
end
