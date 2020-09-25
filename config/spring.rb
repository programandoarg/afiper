
require 'dotenv'
Dotenv.load(
  '.env.test',
  '.env'
)

Spring.application_root = 'spec/dummy'
