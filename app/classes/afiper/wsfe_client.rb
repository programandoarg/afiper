module Afiper
  class WsfeClient
    def initialize(contribuyente)
      @contribuyente = contribuyente
    end

    def solicitar_cae(comprobante)
      if !homologacion && Rails.env != 'production'
        fail 'Guarda al parche'
      end
      parameters = {
        FeCAEReq: {
          FeCabReq: {
            CantReg: 1,
            PtoVta: comprobante.punto_de_venta,
            CbteTipo: comprobante.tipo
          },
          FeDetReq: {
            FECAEDetRequest: {
              Concepto: comprobante.concepto,
              DocTipo: comprobante.receptor_doc_tipo,
              DocNro: comprobante.receptor_doc_nro,
              CbteDesde: comprobante.numero,
              CbteHasta: comprobante.numero,
              CbteFch: comprobante.fecha.strftime("%Y%m%d"),
              ImpTotal: comprobante.total,
              ImpTotConc: comprobante.subtotal_no_gravado,
              ImpNeto: comprobante.subtotal_gravado, # suma de las bases imponibles gravadas
              ImpOpEx: comprobante.subtotal_exento,
              ImpTrib: comprobante.subtotal_tributos,
              ImpIVA: comprobante.subtotal_iva,
              MonId: comprobante.mon_id,
              MonCotiz: comprobante.mon_cotiz,
            }
          }
        }
      }
      if comprobante.subtotal_gravado > 0
        parameters[:FeCAEReq][:FeDetReq][:FECAEDetRequest][:Iva] = {
          AlicIva: comprobante.alicuotas.map do |alicuota|
            {
              Id: alicuota[:tipo_afip],
              BaseImp: alicuota[:base_imponible],
              Importe: alicuota[:importe]
            }
          end
        }
      end
      response = call(:fecae_solicitar, parameters)
      if response[:fe_cab_resp][:resultado] != 'A'
        messages = response[:fe_det_resp][:fecae_det_response][:observaciones][:obs]
        fail WsfeClientError.new ([messages].flatten).to_json
      end
      cae = response[:fe_det_resp][:fecae_det_response][:cae]
      fch_vto = response[:fe_det_resp][:fecae_det_response][:cae_fch_vto]
      # TODO: parsear fecha
      comprobante.update_attributes(cae: cae, vencimiento_cae: fch_vto, afip_result: response.to_json)
      response
    end

    def get_cmp(comprobante)
      @comprobante = comprobante # No borrar
      get_cmp_det(comprobante.tipo, comprobante.punto_de_venta, comprobante.numero)
    end

    def actualizar_comprobante(comprobante)
      res = get_cmp(comprobante)
      comprobante.update_attributes!(cae: res[:cod_autorizacion], fch_vto: res[:fch_vto]) # TODO: tal vez agregar afip_result?
    end

    def get_cmp_det(t, pv, n)
      response = call(:fe_comp_consultar,
        FeCompConsReq: {
          PtoVta: pv,
          CbteNro: n,
          CbteTipo: t
        }
      )
      response = response[:result_get]
      response
    end

    def ultimo_cmp(cbte_tipo, pto_vta)
      response = call(:fe_comp_ultimo_autorizado, PtoVta: pto_vta, CbteTipo: cbte_tipo)
      response[:cbte_nro]
    end

    def get_comp_tot_x_request
      response = call(:fe_comp_tot_x_request)
      response[:reg_x_req]
    end

    def get_puntos_venta
      response = call(:fe_param_get_ptos_venta)
      response[:result_get][:pto_venta]
    end

    def get_tipos_cbte
      response = call(:fe_param_get_tipos_cbte)
      response[:result_get][:cbte_tipo]
    end

    def get_tipos_doc
      response = call(:fe_param_get_tipos_doc)
      response[:result_get][:doc_tipo]
    end

    def get_tipos_monedas
      response = call(:fe_param_get_tipos_monedas)
      response[:result_get][:moneda]
    end

    def get_tipos_concepto
      response = call(:fe_param_get_tipos_concepto)
      response[:result_get][:concepto_tipo]
    end

    def get_tipos_iva
      response = call(:fe_param_get_tipos_iva)
      response[:result_get][:iva_tipo]
    end

    def get_tipos_tributos
      response = call(:fe_param_get_tipos_tributos)
      response[:result_get][:tributo_tipo]
    end

    def get_tipos_cotizaciones(mon_id)
      response = call(:fe_param_get_cotizacion, MonId: mon_id)
    end

    def homologacion
      Rails.env != 'production'
    end

    def call(method, params = {})
      client = build_client
      message = {Auth: auth_hash}
      response = client.call(method, message: message.merge(params))
      if response.body[:"#{method}_response"].present? && response.body[:"#{method}_response"][:"#{method}_result"].present?
        response = response.body[:"#{method}_response"][:"#{method}_result"]
        if response[:errors].present?
          messages = response[:errors][:err]
          fail WsfeClientError.new ([messages].flatten).to_json
        end
        response
      else
        fail WsfeClientError.new ([{code: 0, msg: 'Error en el Web Service de la AFIP'}]).to_json
      end
    end

    # def comercio
    #   return @comercio if @comercio.present?
    #   return @comprobante.comercio if @comprobante.present?
    # end

    def auth_hash
      unless @auth_hash.present?
        token = WsaaToken.where(afiper_contribuyente_id: @contribuyente.id, homologacion: homologacion).where('created_at > ?', Time.zone.now - 6.hours).first
        unless token.present?
          new_token = wsaa
          token = WsaaToken.create(afiper_contribuyente_id: @contribuyente.id, cuit: @contribuyente.cuit, homologacion: homologacion, token: new_token[0], sign: new_token[1])
        end
        @auth_hash = token.auth_hash
      end
      @auth_hash
    end

    def wsaa
      # unless @contribuyente.afip_configured?
      #   fail CustomApplicationError, 'Los certificados de la AFIP no están configurados'
      # end
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
      service = "wsfe"
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
        xml.service service
      end
    end

    def xsd_datetime time
      time.strftime('%Y-%m-%dT%H:%M:%S%z').sub /(\d{2})(\d{2})$/, '\1:\2'
    end

    def build_client
      Savon.client do
        wsdl service_url
        convert_request_keys_to :none
      end
    end

    def service_url
      if homologacion
        "https://wswhomo.afip.gov.ar/wsfev1/service.asmx?WSDL"
      else
        "https://servicios1.afip.gov.ar/wsfev1/service.asmx?WSDL"
      end
    end

    # def dummy
    #   client = build_client
    #   response = client.call(:fe_dummy)
    #   response.body
    # end
  end
end
