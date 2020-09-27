require 'factory_bot_rails'
require 'faker'
require 'byebug'
require 'vcr'
require 'webmock/rspec'
require 'timecop'
# require 'pundit/rspec'

require 'dotenv'

Dotenv.load(
  '.env',
  '.env.test'
)

VCR.configure do |config|
  config.cassette_library_dir = 'spec/cassettes'
  config.default_cassette_options = {
    match_requests_on: [:uri, :method],
    record: :once
  }
  config.hook_into :webmock
  config.configure_rspec_metadata!
end

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods

  config.around(:example, :vcr_cassettes) do |example|
    cassettes = example.metadata[:vcr_cassettes].map { |cas_name| { name: cas_name } }
    VCR.use_cassettes(cassettes) do |cassette|
      Timecop.freeze(VCR.current_cassette.originally_recorded_at || Time.now) do
        example.run
      end
    end
  end
end
