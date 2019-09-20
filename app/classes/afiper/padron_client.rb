require 'savon'
require 'afiper/errors/wsfe_client_error'

module Afiper
  class PadronClient
    def initialize(contribuyente)
      @contribuyente = contribuyente
    end

    def homologacion
      fail 'Configurar Afiper.configuration.padron_homologacion' unless Afiper.configuration.padron_homologacion.in?([true, false])
      Afiper.configuration.padron_homologacion
    end

    def get_persona(cuit)
      response = call(:get_persona, { idPersona: cuit })
      if response.body[:get_persona_response][:persona_return][:error_constancia].present?
        fail Afiper::Errors::WsfeClientError.new(response.body[:get_persona_response][:persona_return][:error_constancia][:error])
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

    def call(method, params = {})
      client = build_client
      message = {token: token.token, sign: token.sign, cuitRepresentada: @contribuyente.cuit}
      response = client.call(method, message: message.merge(params))
      response
    rescue OpenSSL::X509::CertificateError => exception
      fail Afiper::Errors::WsfeClientError.new("Las credenciales para acceder al servicio de AFIP son incorrectas")
    rescue Savon::SOAPFault => exception
      fail Afiper::Errors::WsfeClientError.new(exception.message)
      # if response.body[:"#{method}_response"].present? && response.body[:"#{method}_response"][:"#{method}_result"].present?
      #   response = response.body[:"#{method}_response"][:"#{method}_result"]
      #   if response[:errors].present?
      #     messages = response[:errors][:err]
      #     fail Afiper::Errors::WsfeClientError.new ([messages].flatten).to_json
      #   end
      #   response
      # else
      #   fail Afiper::Errors::WsfeClientError.new ([{code: 0, msg: 'Error en el Web Service de la AFIP'}]).to_json
      # end
    end

    def token
      unless @token.present?
        token = WsaaToken.where(afiper_contribuyente_id: @contribuyente.id, service: service_name, homologacion: homologacion).where('created_at > ?', Time.zone.now - 6.hours).first
        unless token.present?
          new_token = wsaa
          token = WsaaToken.create(afiper_contribuyente_id: @contribuyente.id, service: service_name, cuit: @contribuyente.cuit, homologacion: homologacion, token: new_token[0], sign: new_token[1])
        end
        @token = token
      end
      @token
    end

    def service_name
      "ws_sr_padron_a5"
    end

    def wsaa
      unless @contribuyente.afip_configured?(homologacion)
        fail 'Los certificados de la AFIP no están configurados'
      end
      if homologacion
        raw = @contribuyente.afip_certificado_homologacion
        key_file = @contribuyente.afip_clave_homologacion
        url = "https://wsaahomo.afip.gov.ar/ws/services/LoginCms?wsdl"
      else
        raw = @contribuyente.afip_certificado
        key_file = @contribuyente.afip_clave
        url = "https://wsaa.afip.gov.ar/ws/services/LoginCms?wsdl"
      end
      certificate = OpenSSL::X509::Certificate.new raw

      key = OpenSSL::PKey::RSA.new(key_file)

      signed = OpenSSL::PKCS7::sign certificate, key, generar_tra
      signed = signed.to_pem.lines.to_a[1..-2].join
      client = Savon.client do
        wsdl url
        convert_request_keys_to :none  # or one of [:lower_camelcase, :upcase, :none]
      end
      response = client.call(:login_cms, message: {in0: signed})
      ta = Nokogiri::XML(Nokogiri::XML(response.to_xml).text)
      [ta.css('token').text, ta.css('sign').text]
    end

    def generar_tra
      ttl = 20000

      xml = Builder::XmlMarkup.new indent: 2
      xml.instruct!
      xml.loginTicketRequest version: 1 do
        xml.header do
          xml.uniqueId Time.now.to_i
          xml.generationTime xsd_datetime Time.now - ttl
          # TODO me parece que no le da mucha bola el WS al expirationTime
          xml.expirationTime xsd_datetime Time.now + ttl
        end
        xml.service service_name
      end
    end

    def xsd_datetime time
      time.strftime('%Y-%m-%dT%H:%M:%S%z').sub /(\d{2})(\d{2})$/, '\1:\2'
    end

    def build_client
      url = service_url
      client = Savon.client do
        wsdl url
        convert_request_keys_to :none
      end
    end

    def service_url
      if homologacion
        "https://awshomo.afip.gov.ar/sr-padron/webservices/personaServiceA5?WSDL"
      else
        "https://aws.afip.gov.ar/sr-padron/webservices/personaServiceA5?WSDL"
      end
    end

    def dummy
      client = build_client
      response = client.call(:dummy)
      response.body
    end
  end
end
