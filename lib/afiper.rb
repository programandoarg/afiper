require "afiper/engine"
require "afiper/configuration"
require "afiper/paises"
require "afiper/cuit_paises"

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
