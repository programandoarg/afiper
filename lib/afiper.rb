# frozen_string_literal: true

require 'afiper/engine'
require 'afiper/configuration'

# Afiper
module Afiper
  class << self
    attr_writer :configuration
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield(configuration)
  end
end
