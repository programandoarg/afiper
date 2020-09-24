# frozen_string_literal: true

module Afiper
  # Factura electrónica de exportación
  class WsfexClient < ClienteAfipWs
    def solicitar_cae(comprobante)
      raise 'Guarda al parche' if !homologacion && Rails.env != 'production'

      parameters = {
        Cmp: {
          Id: 100_000_000 + comprobante.id,
          Cbte_Tipo: comprobante.config[:codigo_afip],
          Fecha_cbte: comprobante.fecha.strftime('%Y%m%d'),
          Punto_vta: comprobante.punto_de_venta,
          Cbte_nro: comprobante.numero,
          Tipo_expo: 2, # 1=Bienes 2=Servicios 4=Otros
          Permiso_existente: nil,
          Dst_cmp: comprobante.receptor_codigo_pais || 0,
          Cliente: comprobante.receptor_razon_social,
          Cuit_pais_cliente: comprobante.receptor_cuit_pais || 0,
          Domicilio_cliente: comprobante.receptor_domicilio,
          Id_impositivo: comprobante.exportacion_id_impositivo,
          Moneda_Id: comprobante.moneda_codigo_afip,
          Moneda_ctz: comprobante.moneda_cotizacion,
          # Obs_comerciales: string
          Imp_total: comprobante.total,
          # Obs: string,
          Idioma_cbte: 1, # Español
          Items: {
            Item: {
              # Pro_codigo: string,
              Pro_ds: comprobante.items.first.detalle,
              # Pro_qty: decimal,
              Pro_umed: 0, # FEXGetPARAM_UMed
              # Pro_precio_uni: decimal,
              # Pro_bonificacion: decimal,
              Pro_total_item: comprobante.total
            }
          }
        }
      }
      if comprobante.comprobante_asociado.present?
        parameters[:Cmp][:Cmps_asoc] = {
          Cmp_asoc: {
            Cbte_tipo: comprobante.comprobante_asociado.config[:codigo_afip],
            Cbte_punto_vta: comprobante.comprobante_asociado.punto_de_venta,
            Cbte_nro: comprobante.comprobante_asociado.numero,
            Cbte_cuit: comprobante.comprobante_asociado.emisor_cuit
          }
        }
      else
        parameters[:Cmp][:Fecha_pago] = comprobante.fecha.strftime('%Y%m%d')
      end
      puts '###############################################################################'
      puts '###############################################################################'
      puts '###############################################################################'
      pp parameters
      response = call(:fex_authorize, parameters)
      unless response[:fex_result_auth].present?
        messages = response[:fex_err][:err_msg]
        raise Afiper::Errors::WsfeClientError, [messages].flatten.to_json
      end
      cae = response[:fex_result_auth][:cae]
      fch_vto = response[:fex_result_auth][:fch_venc_cae]
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
                      })
      response[:result_get]
    end

    def ultimo_cmp
      # validar_tipo(tipo)
      # tipo_afip = Comprobante.find_config(:nombre, tipo)[:codigo_afip]
      # response = call(:FEXGetLastID)
      call(:fex_get_last_id)

      # response[:cbte_nro].to_i
    end

    def service_name
      'wsfex'
    end

    def service_url
      if homologacion
        'https://wswhomo.afip.gov.ar/wsfexv1/service.asmx?WSDL'
      else
        'https://servicios1.afip.gov.ar/wsfexv1/service.asmx?WSDL'
      end
    end

    # def dummy
    #   client = build_client
    #   response = client.call(:fe_dummy)
    #   response.body
    # end

    def call(method, params = {})
      client = build_client
      message = { Auth: auth_hash }
      response = client.call(method, message: message.deep_merge(params))
      if response.body[:"#{method}_response"].present? &&
         response.body[:"#{method}_response"][:"#{method}_result"].present?
        response = response.body[:"#{method}_response"][:"#{method}_result"]
        if response[:fex_err].present? && response[:fex_err][:err_code].to_i.positive?
          messages = [response[:fex_err]].flatten.map do |error|
            { code: error[:err_code], msg: error[:err_msg] }
          end
          raise Afiper::Errors::WsfeClientError, messages.to_json
        end
        response
      else
        raise Afiper::Errors::WsfeClientError,
              [{ code: 0, msg: 'Error en el Web Service de la AFIP' }].to_json
      end
    end

    # fetch_comprobantes(:factura_a, 1)
    def fetch_comprobantes(tipo, pto_vta)
      validar_tipo(tipo)
      ultimo = ultimo_cmp(tipo, pto_vta)
      (1..ultimo).each do |numero|
        if @contribuyente.comprobantes.where(tipo: Comprobante.tipos[tipo],
                                             punto_de_venta: pto_vta, numero: numero).exists?
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
        comprobante.items << Item.new(tipo: 6, codigo: '', detalle: 'No gravado',
                                      importe: result[:imp_tot_conc])
        comprobante.items << Item.new(tipo: 7, codigo: '', detalle: 'Exento',
                                      importe: result[:imp_op_ex])
        if result[:iva] && result[:iva][:alic_iva]
          [result[:iva][:alic_iva]].flatten.each do |iva|
            comprobante.items << Item.new(tipo: Item.tipo_from_afip(iva[:id]),
                                          codigo: '', detalle: "Gravado #{iva[:id]}",
                                          importe: iva[:base_imp])
          end
        end
        comprobante.save!
      end
    end

    def validar_tipo(tipo)
      return unless Comprobante.find_config(:nombre, tipo).nil?

      raise Afiper::Errors::WsfeClientError, "Tipo erróneo #{tipo}"
    end
  end
end
