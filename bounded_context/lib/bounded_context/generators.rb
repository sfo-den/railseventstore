require 'rails/generators'

module BoundedContext
  module Generators
    class Generator < Rails::Generators::NamedBase
      private

      def bounded_context_namespace
        name.camelize
      end

      def bounded_context_name
        name.underscore
      end
    end

    class Module < Generator
      source_root File.expand_path(File.join(File.dirname(__FILE__), 'templates'))
      hook_for :test_framework

      def create_bounded_context
        template "module.rb", "#{bounded_context_name}/lib/#{bounded_context_name}.rb"

        application do
          "config.paths.add '#{bounded_context_name}/lib', eager_load: true"
        end
      end
    end

    class Rspec < Generator
      source_root File.expand_path(File.join(File.dirname(__FILE__), 'templates'))

      def spec_helper
        template "spec_helper.rb", "#{bounded_context_name}/spec/spec_helper.rb"
      end
    end

    class TestUnit < Generator
      source_root File.expand_path(File.join(File.dirname(__FILE__), 'templates'))

      def test_helper
        template "test_helper.rb", "#{bounded_context_name}/test/test_helper.rb"
      end
    end
  end
end
