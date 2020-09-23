module Afiper

  # para debuguear
  # client = self.build_client
  # response = client.call(:fecae_solicitar, message: me)
  # request = client.build_request(:fecae_solicitar, message: me)

  # Factura electrónica
  class WsfeClient < ClienteAfipWs
    def solicitar_cae(comprobante)
      if !homologacion && Rails.env != 'production'
        fail 'Guarda al parche'
      end
      parameters = {
        FeCAEReq: {
          FeCabReq: {
            CantReg: 1,
            PtoVta: comprobante.punto_de_venta,
            CbteTipo: comprobante.config[:codigo_afip]
          },
          FeDetReq: {
            FECAEDetRequest: {
              Concepto: comprobante.concepto_afip,
              DocTipo: comprobante.receptor_doc_tipo_values[:codigo_afip],
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
              MonId: comprobante.moneda_codigo_afip,
              MonCotiz: comprobante.moneda_cotizacion,
            }
          }
        }
      }
      if comprobante.tiene_servicios?
        begin
          parameters[:FeCAEReq][:FeDetReq][:FECAEDetRequest][:FchServDesde] = comprobante.fecha_servicio_desde.strftime("%Y%m%d")
          parameters[:FeCAEReq][:FeDetReq][:FECAEDetRequest][:FchServHasta] = comprobante.fecha_servicio_hasta.strftime("%Y%m%d")
          parameters[:FeCAEReq][:FeDetReq][:FECAEDetRequest][:FchVtoPago] = comprobante.fecha_vencimiento_pago.strftime("%Y%m%d")
        rescue NoMethodError => e
        end
      end
      if comprobante.subtotal_gravado > 0
        parameters[:FeCAEReq][:FeDetReq][:FECAEDetRequest][:Iva] = {
          AlicIva: comprobante.alicuotas.map do |alicuota|
            {
              Id: alicuota[:codigo_alicuota],
              BaseImp: alicuota[:base_imponible],
              Importe: alicuota[:importe]
            }
          end
        }
      end
      response = call(:fecae_solicitar, parameters)
      if response[:fe_cab_resp][:resultado] != 'A'
        messages = response[:fe_det_resp][:fecae_det_response][:observaciones][:obs]
        fail Afiper::Errors::WsfeClientError.new ([messages].flatten).to_json
      end
      cae = response[:fe_det_resp][:fecae_det_response][:cae]
      fch_vto = response[:fe_det_resp][:fecae_det_response][:cae_fch_vto]
      # TODO: parsear fecha
      # fch_vto = Date.strptime(result[:fch_vto], '%Y%m%d'),
      comprobante.update_attributes(cae: cae, vencimiento_cae: fch_vto, afip_result: response.to_json)
      response
    end

    def get_cmp(comprobante)
      @comprobante = comprobante # No borrar
      get_cmp_det(comprobante.tipo.to_sym, comprobante.punto_de_venta, comprobante.numero)
    end

    def actualizar_comprobante(comprobante)
      res = get_cmp(comprobante)
      comprobante.update_attributes!(cae: res[:cod_autorizacion], vencimiento_cae: res[:fch_vto]) # TODO: tal vez agregar afip_result?
    end

    def get_cmp_det(tipo, punto_de_venta, numero)
      validar_tipo(tipo)
      tipo_afip = Comprobante.find_config(:nombre, tipo)[:codigo_afip]
      response = call(:fe_comp_consultar,
        FeCompConsReq: {
          PtoVta: punto_de_venta,
          CbteNro: numero,
          CbteTipo: tipo_afip
        }
      )
      response = response[:result_get]
      response
    end

    def ultimo_cmp(tipo, pto_vta)
      validar_tipo(tipo)
      tipo_afip = Comprobante.find_config(:nombre, tipo)[:codigo_afip]
      response = call(:fe_comp_ultimo_autorizado, PtoVta: pto_vta, CbteTipo: tipo_afip)
      response[:cbte_nro].to_i
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

    def service_name
      "wsfe"
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

    # fetch_comprobantes(:factura_a, 1)
    def fetch_comprobantes(tipo, pto_vta)
      validar_tipo(tipo)
      ultimo = ultimo_cmp(tipo, pto_vta)
      (1..ultimo).each do |numero|
        unless @contribuyente.comprobantes.where(tipo: Comprobante.tipos[tipo], punto_de_venta: pto_vta, numero: numero).exists?
          result = get_cmp_det(tipo, pto_vta, numero)
          comprobante = @contribuyente.comprobantes.new(
            tipo: tipo,
            fecha: Date.strptime(result[:cbte_fch], '%Y%m%d'),
            punto_de_venta: pto_vta,
            numero: numero,
            receptor_doc_tipo: result[:doc_tipo],
            receptor_doc_nro: result[:doc_nro],
            receptor_razon_social: "-", # TODO

            concepto: result[:concepto].to_i,
            mon_id: result[:mon_id],
            mon_cotiz: result[:mon_cotiz],

            creado_por_el_sistema: false,
            fiscal: true,

            cae: result[:cod_autorizacion],
            vencimiento_cae: Date.strptime(result[:fch_vto], '%Y%m%d'),
            afip_result: result
          )
          comprobante.items << Item.new(tipo: 6, codigo: '', detalle: 'No gravado', importe: result[:imp_tot_conc])
          comprobante.items << Item.new(tipo: 7, codigo: '', detalle: 'Exento', importe: result[:imp_op_ex])
          if result[:iva] && result[:iva][:alic_iva]
            [result[:iva][:alic_iva]].flatten.each do |iva|
              comprobante.items << Item.new(tipo: Item.tipo_from_afip(iva[:id]), codigo: '', detalle: "Gravado #{iva[:id]}", importe: iva[:base_imp])
            end
          end
          comprobante.save!
        end
      end
    end

    def validar_tipo(tipo)
      return unless Comprobante.find_config(:nombre, tipo).nil?
      raise Afiper::Errors::WsfeClientError.new "Tipo erróneo #{tipo}"
    end
  end
end