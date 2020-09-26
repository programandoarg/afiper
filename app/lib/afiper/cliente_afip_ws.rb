# frozen_string_literal: true

require 'savon'
require 'afiper/errors/wsfe_client_error'

module Afiper
  # WSAA: Autenticación para todos los web services de AFIP
  class ClienteAfipWs
    def initialize(contribuyente)
      @contribuyente = contribuyente
    end

    def homologacion
      unless Afiper.configuration.wsfe_homologacion.in?([true, false])
        raise 'Afiper: Error de configuración' \
              'Agregar config/initializers/afiper.rb' \
              '  Afiper.configure do |config|' \
              '    config.wsfe_homologacion = true' \
              '  end'
      end

      Afiper.configuration.wsfe_homologacion
    end

    def call(method, params = {})
      client = build_client
      message = { Auth: auth_hash }
      response = client.call(method, message: message.deep_merge(params))
      # puts response.as_json
      # puts %("response.body[:"#{method}_response"].present? && response.body[:"#{method}_response"][:"#{method}_result"].present?")
      if response.body[:"#{method}_response"].present? && response.body[:"#{method}_response"][:"#{method}_result"].present?
        response = response.body[:"#{method}_response"][:"#{method}_result"]
        if response[:errors].present?
          messages = response[:errors][:err]
          raise Afiper::Errors::WsfeClientError, [messages].flatten.to_json
        end
        response
      else
        raise Afiper::Errors::WsfeClientError, [{ code: 0, msg: 'Error en el Web Service de la AFIP' }].to_json
      end
    rescue SocketError => e
      raise Afiper::Errors::WsfeClientError, [{ code: 90000111, message: 'Error de conexión' }].to_json
    end

    def auth_hash
      unless @auth_hash.present?
        token = WsaaToken.where(contribuyente: @contribuyente, service: service_name, homologacion: homologacion).where('created_at > ?', Time.zone.now - 6.hours).first
        unless token.present?
          new_token = wsaa
          token = WsaaToken.create(contribuyente: @contribuyente, service: service_name, cuit: @contribuyente.cuit, homologacion: homologacion, token: new_token[0], sign: new_token[1])
        end
        @auth_hash = token.auth_hash
      end
      @auth_hash
    end

    def wsaa
      unless @contribuyente.afip_configured?(homologacion)
        raise 'Los certificados de la AFIP no están configurados'
      end

      if homologacion
        raw = @contribuyente.afip_certificado_homologacion
        key_file = @contribuyente.afip_clave_homologacion
        url = 'https://wsaahomo.afip.gov.ar/ws/services/LoginCms?wsdl'
      else
        raw = @contribuyente.afip_certificado
        key_file = @contribuyente.afip_clave
        url = 'https://wsaa.afip.gov.ar/ws/services/LoginCms?wsdl'
      end

      if !Rails.env.test? || ENV['FORCE_WSAA'] == 'true'
        certificate = OpenSSL::X509::Certificate.new raw
        key = OpenSSL::PKey::RSA.new(key_file)
        signed = OpenSSL::PKCS7.sign certificate, key, generar_tra
        signed = signed.to_pem.lines.to_a[1..-2].join
      else
        signed = 'vcr_mock'
      end
      client = Savon.client do
        wsdl url
        convert_request_keys_to :none # or one of [:lower_camelcase, :upcase, :none]
      end
      response = client.call(:login_cms, message: { in0: signed })
      ta = Nokogiri::XML(Nokogiri::XML(response.to_xml).text)
      [ta.css('token').text, ta.css('sign').text]
    end

    def generar_tra
      ttl = 20_000

      xml = Builder::XmlMarkup.new indent: 2
      xml.instruct!
      xml.loginTicketRequest version: 1 do
        xml.header do
          xml.uniqueId Time.now.to_i
          xml.generationTime xsd_datetime Time.now - ttl
          # TODO: me parece que no le da mucha bola el WS al expirationTime
          xml.expirationTime xsd_datetime Time.now + ttl
        end
        xml.service service_name
      end
    end

    def xsd_datetime(time)
      time.strftime('%Y-%m-%dT%H:%M:%S%z').sub(/(\d{2})(\d{2})$/, '\1:\2')
    end

    def build_client
      url = service_url
      client = Savon.client do
        wsdl url
        convert_request_keys_to :none
      end
    end
  end
end
