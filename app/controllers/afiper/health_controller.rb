# require 'afiper/application_controller'

module Afiper
  class HealthController < ApplicationController
    def health
      check_padron
      check_ssl_cert_file

      render plain: "ok"
    rescue StandardError => e
      render plain: e.message, status: 500
    end

    private

    def check_ssl_cert_file
      return if ENV.fetch("SSL_CERT_FILE").present? && File.read(ENV.fetch("SSL_CERT_FILE")).present?

      raise "wrong or null SSL_CERT_FILE: #{ENV.fetch("SSL_CERT_FILE")}"
    end

    def check_padron
      contribuyente = Afiper::Contribuyente.for_padron
      client = contribuyente.padron_client
      client.get_persona("20351404478")[:nombre] == "MARTIN ROSSO"
    end
  end
end
