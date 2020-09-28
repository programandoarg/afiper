require 'simplecov'
SimpleCov.start 'rails'

require 'dotenv'

Dotenv.load(
  '.env',
  '.env.test'
)

Spring.application_root = 'spec/dummy'
Spring.watch File.expand_path('../app/lib/afiper/errors.rb', __dir__)
