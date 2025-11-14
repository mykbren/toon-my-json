# frozen_string_literal: true

require_relative 'lib/toon_my_json/version'

Gem::Specification.new do |spec|
  spec.name = 'toon_my_json'
  spec.version = ToonMyJson::VERSION
  spec.authors = ['mykbren']
  spec.email = ['myk.bren@gmail.com']

  spec.summary = 'Bidirectional JSON - TOON (Token-Oriented Object Notation) converter'
  spec.description = 'A Ruby gem for converting between JSON and TOON format. ' \
                     'TOON is a compact serialization format designed for LLMs that reduces ' \
                     'token usage by 30-60% compared to JSON. Supports bidirectional conversion, ' \
                     'tabular arrays, nested structures, and lossless roundtrips.'
  spec.homepage = 'https://github.com/mykbren/toon-my-json'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.0.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/mykbren/toon-my-json'
  spec.metadata['changelog_uri'] = 'https://github.com/mykbren/toon-my-json/blob/main/CHANGELOG.md'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.glob('lib/**/*') + Dir.glob('bin/*') + ['README.md', 'CHANGELOG.md', 'LICENSE.txt', 'Rakefile']
  spec.bindir = 'bin'
  spec.executables = ['toon']
  spec.require_paths = ['lib']

  spec.add_dependency 'json', '~> 2.0'

  spec.add_development_dependency 'benchmark-ips', '~> 2.0'
  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'simplecov', '~> 0.22'
end
