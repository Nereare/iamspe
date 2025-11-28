# frozen_string_literal: true

require_relative 'lib/iamspe/meta'

Gem::Specification.new do |spec|
  spec.name        = Iamspe::SLUG
  spec.version     = Iamspe::VERSION
  spec.license     = Iamspe::LICENSE
  spec.author      = Iamspe::AUTHOR
  spec.email       = Iamspe::AUTHOR_EMAIL
  spec.summary     = Iamspe::DESCRIPTION
  spec.homepage    = 'https://github.com/Nereare/iamspe'

  spec.required_ruby_version = '~> 3.2'

  spec.metadata['source_code_uri']   = spec.homepage
  spec.metadata['bug_tracker_uri']   = 'https://github.com/Nereare/iamspe/issues'
  spec.metadata['changelog_uri']     = 'https://github.com/Nereare/iamspe/blob/master/CHANGELOG.md'
  # TODO: spec.metadata['documentation_uri'] = ''

  spec.files = Dir[
    'lib/**/*.rb',
    'sig/*',
    'spec/*.rb',
    '.ruby-version',
    'LICENSE.md',
    'Rakefile'
  ]
  spec.bindir        = 'bin'
  # TODO: spec.executables   = 'repo_templater'
  spec.require_paths = %w[lib]

  spec.add_dependency 'activesupport', '~> 8.1', '>= 8.1.1'
  spec.add_dependency 'sqlite3', '~> 1.3', '>= 1.3.11'
  spec.add_dependency 'tty-font', '~> 0.5.0'
  spec.add_dependency 'tty-pie', '~> 0.4.0'
  spec.add_dependency 'tty-prompt', '~> 0.23'
  spec.add_dependency 'tty-table', '~> 0.12.0'
  spec.add_dependency 'tzinfo'

  spec.add_development_dependency 'rake', '~> 13.3'
  spec.add_development_dependency 'rdoc', '~> 6.15'
  spec.add_development_dependency 'rspec', '~> 3.13'
  spec.add_development_dependency 'rubocop', '~> 1.81', '>= 1.81.1'
  spec.add_development_dependency 'rubocop-rake', '~> 0.7.1'
  spec.add_development_dependency 'rubocop-rspec', '~> 3.7'
end
