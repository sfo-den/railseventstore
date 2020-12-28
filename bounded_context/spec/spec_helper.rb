# frozen_string_literal: true

require 'bounded_context'
require 'securerandom'
require 'rails/gem_version'
require_relative '../../support/helpers/rspec_defaults'
require_relative '../../support/helpers/silence_stdout'

module GeneratorHelper
  def dummy_app_name
    "dummy_#{Rails::VERSION::MAJOR}_#{Rails::VERSION::MINOR}"
  end

  def dummy_app_root
    File.join(__dir__, dummy_app_name)
  end

  def destination_root
    @destination_root ||= File.join(File.join(__dir__, 'tmp'), SecureRandom.hex)
  end

  def prepare_destination_root
    FileUtils.mkdir_p(destination_root)
    raise "App #{dummy_app_name} doesn't exist" unless File.exist?(dummy_app_root)
    FileUtils.cp_r("#{dummy_app_root}/.", destination_root)
  end

  def nuke_destination_root
    FileUtils.rm_r(destination_root)
  end

  def run_generator(generator_args)
    SilenceStdout.silence_stdout { ::BoundedContext::Generators::BoundedContextGenerator.start(generator_args, destination_root: destination_root) }
  end

  def system_run_generator(genetator_args)
    system("cd #{destination_root}; bin/rails g bounded_context #{genetator_args.join(' ')} -q")
  end
end
