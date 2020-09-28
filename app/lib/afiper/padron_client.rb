# frozen_string_literal: true

require 'savon'

module Afiper
  # API Padrón
  class PadronClient < ClienteAfipWs
    def initialize(contribuyente)
      super(
        contribuyente: contribuyente,
        service_name: 'ws_sr_padron_a5',
        service_url: service_url
      )
    end

    def service_url
      if homologacion
        'https://awshomo.afip.gov.ar/sr-padron/webservices/personaServiceA5?WSDL'
      else
        'https://aws.afip.gov.ar/sr-padron/webservices/personaServiceA5?WSDL'
      end
    end

    def homologacion
      unless Afiper.configuration.padron_homologacion.in?([true, false])
        raise 'Configurar Afiper.configuration.padron_homologacion'
      end

      Afiper.configuration.padron_homologacion
    end

    def get_persona(cuit)
      response = call_auth(:get_persona, { idPersona: cuit })
      if response.body[:get_persona_response][:persona_return][:error_constancia].present?
        raise Afiper::Error, response.body[:get_persona_response][:persona_return][:error_constancia][:error]
      end

      response = response.body[:get_persona_response][:persona_return][:datos_generales]
      domicilio = response[:domicilio_fiscal]
      nombre = "#{response[:nombre]} #{response[:apellido]} #{response[:razon_social]}".strip
      {
        nombre: nombre,
        cuit: cuit,
        tipo_persona: response[:tipo_persona],
        cod_postal: domicilio[:cod_postal],
        descripcion_provincia: domicilio[:descripcion_provincia],
        direccion: domicilio[:direccion],
        id_provincia: domicilio[:id_provincia]
      }
    end

    def call_auth(method, params = {})
      message = token.auth_hash_padron
      call_raw(@service_url, method, message.merge(params))
    rescue OpenSSL::X509::CertificateError => e
      raise Error, 'Las credenciales para acceder al servicio de AFIP son incorrectas'
    rescue Savon::SOAPFault => e
      raise Error, e.message
    rescue Savon::HTTPError => e
      raise ErrorTemporal, 'Hubo un error al comunicarse con el sistema de AFIP'
    end
  end
end
