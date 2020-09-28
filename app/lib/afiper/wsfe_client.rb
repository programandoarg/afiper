# frozen_string_literal: true

module Afiper
  # Factura electrónica
  class WsfeClient < ClienteAfipWs
    def initialize(contribuyente)
      super(
        contribuyente: contribuyente,
        service_name: 'wsfe',
        service_url: service_url
      )
    end

    def service_url
      if homologacion
        'https://wswhomo.afip.gov.ar/wsfev1/service.asmx?WSDL'
      else
        'https://servicios1.afip.gov.ar/wsfev1/service.asmx?WSDL'
      end
    end

    def autorizar_comprobante(comprobante)
      if !homologacion && Rails.env != 'production'
        raise Error, 'No se puede crear un comprobante real fuera del entorno de producción'
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
              CbteFch: comprobante.fecha.strftime('%Y%m%d'),
              ImpTotal: comprobante.total,
              ImpTotConc: comprobante.subtotal_no_gravado,
              ImpNeto: comprobante.subtotal_gravado, # suma de las bases imponibles gravadas
              ImpOpEx: comprobante.subtotal_exento,
              ImpTrib: comprobante.subtotal_tributos,
              ImpIVA: comprobante.subtotal_iva,
              MonId: comprobante.moneda_codigo_afip,
              MonCotiz: comprobante.moneda_cotizacion
            }
          }
        }
      }
      if comprobante.tiene_servicios?
        begin
          parameters[:FeCAEReq][:FeDetReq][:FECAEDetRequest][:FchServDesde] = comprobante.fecha_servicio_desde.strftime('%Y%m%d')
          parameters[:FeCAEReq][:FeDetReq][:FECAEDetRequest][:FchServHasta] = comprobante.fecha_servicio_hasta.strftime('%Y%m%d')
          parameters[:FeCAEReq][:FeDetReq][:FECAEDetRequest][:FchVtoPago] = comprobante.fecha_vencimiento_pago.strftime('%Y%m%d')
        rescue NoMethodError => e
        end
      end
      if comprobante.subtotal_gravado.positive?
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
      response = call_auth(:fecae_solicitar, parameters)
      if response[:fe_cab_resp][:resultado] != 'A'
        messages = response[:fe_det_resp][:fecae_det_response][:observaciones][:obs]
        raise AfipWsError, messages
      end
      cae = response[:fe_det_resp][:fecae_det_response][:cae]
      fch_vto = response[:fe_det_resp][:fecae_det_response][:cae_fch_vto]
      # parsear fecha?
      # fch_vto = Date.strptime(result[:fch_vto], '%Y%m%d'),
      comprobante.update_attributes(cae: cae, vencimiento_cae: fch_vto, afip_result: response.to_json)
      true
    end

    def autorizar_o_actualizar(comprobante)
      autorizar_comprobante(comprobante)
    rescue AfipWsError => error_original
      if error_original.error_code == '10016' # Si no es el próximo a autorizar
        begin
          actualizar_comprobante(comprobante)
        rescue Error
          raise error_original
        end
      else
        raise error_original
      end
    end

    def get_cmp(comprobante)
      @comprobante = comprobante # No borrar
      get_cmp_det(comprobante.tipo.to_sym, comprobante.punto_de_venta, comprobante.numero)
    end

    def actualizar_comprobante(comprobante)
      res = get_cmp(comprobante)
      comprobante.update_attributes!(cae: res[:cod_autorizacion], vencimiento_cae: res[:fch_vto]) # TODO: tal vez agregar afip_result?
      true
    end

    def get_cmp_det(tipo, punto_de_venta, numero)
      validar_tipo(tipo)
      tipo_afip = Comprobante.find_config(:nombre, tipo)[:codigo_afip]
      response = call_auth(:fe_comp_consultar,
                      FeCompConsReq: {
                        PtoVta: punto_de_venta,
                        CbteNro: numero,
                        CbteTipo: tipo_afip
                      })
      response[:result_get]
    end

    def ultimo_cmp(tipo, pto_vta)
      validar_tipo(tipo)
      tipo_afip = Comprobante.find_config(:nombre, tipo)[:codigo_afip]
      response = call_auth(:fe_comp_ultimo_autorizado, PtoVta: pto_vta, CbteTipo: tipo_afip)
      response[:cbte_nro].to_i
    end

    def get_comp_tot_x_request
      response = call_auth(:fe_comp_tot_x_request)
      response[:reg_x_req]
    end

    def get_puntos_venta
      response = call_auth(:fe_param_get_ptos_venta)
      response[:result_get][:pto_venta]
    end

    def get_tipos_cbte
      response = call_auth(:fe_param_get_tipos_cbte)
      response[:result_get][:cbte_tipo]
    end

    def get_tipos_doc
      response = call_auth(:fe_param_get_tipos_doc)
      response[:result_get][:doc_tipo]
    end

    def get_tipos_monedas
      response = call_auth(:fe_param_get_tipos_monedas)
      response[:result_get][:moneda]
    end

    def get_tipos_concepto
      response = call_auth(:fe_param_get_tipos_concepto)
      response[:result_get][:concepto_tipo]
    end

    def get_tipos_iva
      response = call_auth(:fe_param_get_tipos_iva)
      response[:result_get][:iva_tipo]
    end

    def get_tipos_tributos
      response = call_auth(:fe_param_get_tipos_tributos)
      response[:result_get][:tributo_tipo]
    end

    def get_tipos_cotizaciones(mon_id)
      response = call_auth(:fe_param_get_cotizacion, MonId: mon_id)
    end

    # fetch_comprobantes(:factura_a, 1)
    def fetch_comprobantes(tipo, pto_vta)
      validar_tipo(tipo)
      ultimo = ultimo_cmp(tipo, pto_vta)
      (1..ultimo).each do |numero|
        if @contribuyente.comprobantes.where(tipo: Comprobante.tipos[tipo], punto_de_venta: pto_vta, numero: numero).exists?
          next
        end

        result = get_cmp_det(tipo, pto_vta, numero)
        comprobante = @contribuyente.comprobantes.new(
          tipo: tipo,
          fecha: Date.strptime(result[:cbte_fch], '%Y%m%d'),
          punto_de_venta: pto_vta,
          numero: numero,
          receptor_doc_tipo: result[:doc_tipo],
          receptor_doc_nro: result[:doc_nro],
          receptor_razon_social: '-', # TODO

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

    def validar_tipo(tipo)
      return unless Comprobante.find_config(:nombre, tipo).nil?

      raise Error, "Tipo erróneo #{tipo}"
    end
  end
end
