# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)

# Maintain your gem's version:
require 'afiper/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|
  spec.name        = 'afiper'
  spec.version     = Afiper::VERSION
  spec.authors     = ['Martín Rosso']
  spec.email       = ['mrosso10@gmail.com']
  spec.homepage    = ''
  spec.summary     = 'Summary of Afiper.'
  spec.description = 'Description of Afiper.'
  spec.license     = 'MIT'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise 'RubyGems 2.0 or newer is required to protect against ' \
      'public gem pushes.'
  end

  spec.files = Dir['{app,config,db,lib}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.md']

  spec.test_files = Dir['spec/**/*']

  spec.add_dependency 'barby', '~> 0.6.4'
  spec.add_dependency 'enumerize'
  spec.add_dependency 'paranoia'
  spec.add_dependency 'pg'
  spec.add_dependency 'rails', '~> 5.2'
  spec.add_dependency 'savon', '~> 2.10.0'
  spec.add_dependency 'sidekiq', '~> 5.2'

  spec.add_development_dependency 'database_cleaner'
  spec.add_development_dependency 'factory_bot_rails'
  spec.add_development_dependency 'faker'
  spec.add_development_dependency 'fuubar'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'byebug'
  spec.add_development_dependency 'rspec-rails'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'rubocop-rspec'
  spec.add_development_dependency 'simplecov', '~> 0.17.1'
  spec.add_development_dependency 'annotate'
  spec.add_development_dependency 'spring'
  spec.add_development_dependency 'spring-commands-rspec'
  spec.add_development_dependency 'dotenv-rails'
end
