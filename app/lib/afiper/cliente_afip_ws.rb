# frozen_string_literal: true

require 'savon'

module Afiper
  # WSAA: Autenticación para todos los web services de AFIP
  class ClienteAfipWs
    def initialize(options = {})
      @cuit = options[:cuit]
      @afip_clave_privada = options[:afip_clave_privada]
      @afip_certificado = options[:afip_certificado]
      @service_name = options[:service_name]
      @service_url = options[:service_url]
    end

    def homologacion
      Afiper.configuration.wsfe_homologacion
    end

    def call_auth(method, params = {})
      message = { Auth: token.auth_hash_wsfe }
      response = call_raw(@service_url, method, message.deep_merge(params))

      if response.body[:"#{method}_response"].present? &&
         response.body[:"#{method}_response"][:"#{method}_result"].present?
        response = response.body[:"#{method}_response"][:"#{method}_result"]
        handle_errores(response)

        response
      else
        raise ErrorTemporal, 'Error en el Web Service de la AFIP'
      end
    end

    def token
      unless @token.present?
        @token = WsaaToken.where(cuit: @cuit, service: @service_name, homologacion: homologacion).where('created_at > ?', Time.zone.now - 6.hours).first
        unless @token.present?
          new_token = wsaa
          @token = WsaaToken.create(cuit: @cuit, service: @service_name, homologacion: homologacion, token: new_token[0], sign: new_token[1])
        end
      end
      @token
    end

    def timeout_errors
      excs = [HTTPI::TimeoutError, Errno::ECONNRESET]
      defined?(HTTPClient) && excs << HTTPClient::ReceiveTimeoutError
      excs
    end

    def call_raw(url, method, message)
      client = Savon.client do
        wsdl url
        convert_request_keys_to :none
      end
      response = client.call(method, message: message)
    rescue *timeout_errors
      raise ErrorTemporal, 'Error interno en el servidor de la AFIP'
    rescue Savon::Error
      raise ErrorTemporal, 'Error interno en el servidor de la AFIP'
    rescue SocketError
      raise ErrorTemporal, 'Error de conexión'
    end

    def wsaa
      unless @afip_clave_privada.present? && @afip_certificado.present?
        raise Error, 'Los certificados de la AFIP no están configurados'
      end

      if homologacion
        url = 'https://wsaahomo.afip.gov.ar/ws/services/LoginCms?wsdl'
      else
        url = 'https://wsaa.afip.gov.ar/ws/services/LoginCms?wsdl'
      end

      certificate = OpenSSL::X509::Certificate.new @afip_certificado
      key = OpenSSL::PKey::RSA.new(@afip_clave_privada)
      signed = OpenSSL::PKCS7.sign certificate, key, generar_tra
      signed = signed.to_pem.lines.to_a[1..-2].join

      response = call_raw(url, :login_cms, in0: signed)
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
          # me parece que no le da mucha bola el WS al expirationTime
          xml.expirationTime xsd_datetime Time.now + ttl
        end
        xml.service @service_name
      end
    end

    def xsd_datetime(time)
      time.strftime('%Y-%m-%dT%H:%M:%S%z').sub(/(\d{2})(\d{2})$/, '\1:\2')
    end
  end
end
