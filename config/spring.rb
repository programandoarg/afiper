require 'dotenv'

Dotenv.load(
  '.env',
  '.env.test'
)

Spring.application_root = 'spec/dummy'
