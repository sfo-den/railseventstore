lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ruby_event_store/rom/version'

Gem::Specification.new do |spec|
  spec.name          = 'ruby_event_store-rom'
  spec.version       = RubyEventStore::ROM::VERSION
  spec.licenses      = ['MIT']
  spec.authors       = ['Joel Van Horn']
  spec.email         = ['joel@joelvanhorn.com']

  spec.summary       = 'ROM events repository for Ruby Event Store'
  spec.description   = "Implementation of events repository based on ROM for Ruby Event Store'"
  spec.homepage      = 'https://railseventstore.org'
  spec.metadata    = {
    'homepage_uri' => 'https://railseventstore.org/',
    'changelog_uri' => 'https://github.com/RailsEventStore/rails_event_store/releases',
    'source_code_uri' => 'https://github.com/RailsEventStore/rails_event_store',
    'bug_tracker_uri' => 'https://github.com/RailsEventStore/rails_event_store/issues'
  }

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'dry-initializer', '= 2.5.0'
  spec.add_dependency 'dry-types', '~> 0.12.2'
  spec.add_dependency 'rom-changeset', '>= 1.0'
  spec.add_dependency 'rom-repository', '>= 2.0'
  spec.add_dependency 'rom-sql', '>= 2.4'
  spec.add_dependency 'ruby_event_store', '= 0.35.0'
  spec.add_dependency 'sequel', '>= 4.49'
end
