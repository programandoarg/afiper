require 'factory_bot_rails'
require 'faker'
require 'byebug'
# require 'pundit/rspec'

require 'dotenv'

Dotenv.load(
  '.env.test',
  '.env'
)

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
end
