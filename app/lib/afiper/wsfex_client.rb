# frozen_string_literal: true

module Afiper
  # Factura electrónica de exportación
  class WsfexClient < ClienteAfipWs
    def initialize(cuit, afip_clave_privada, afip_certificado)
      super(
        cuit: cuit,
        afip_clave_privada: afip_clave_privada,
        afip_certificado: afip_certificado,
        service_name: 'wsfex',
        service_url: service_url
      )
    end

    def service_url
      if homologacion
        'https://wswhomo.afip.gov.ar/wsfexv1/service.asmx?WSDL'
      else
        'https://servicios1.afip.gov.ar/wsfexv1/service.asmx?WSDL'
      end
    end

    def handle_errores(response)
      if response[:fex_err].present? && response[:fex_err][:err_code].to_i.positive?
        errores = [response[:fex_err]].flatten.map do |error|
          { code: error[:err_code], msg: error[:err_msg] }
        end
        raise AfipWsError, errores
      end
    end

    def fex_get_last_cmp(tipo, pto_vta)
      tipo_afip = Comprobante.find_config(:nombre, tipo)[:codigo_afip]
      response = call_auth(:fex_get_last_cmp, :'Auth' => { :'Pto_venta' => pto_vta, :'Cbte_Tipo' => tipo_afip })
      # unless response[:fex_result_last_cmp].present?
      #   messages = response[:fex_err][:err_msg]
      #   raise Afiper::Error, [messages].flatten.to_json
      # end
      nro = response[:fex_result_last_cmp][:cbte_nro].to_i
      nro
    end

    def autorizar_comprobante(comprobante)
      if !homologacion && Rails.env != 'production'
        raise Error, 'No se puede crear un comprobante real fuera del entorno de producción'
      end
      response = call_auth(:fex_authorize, parameters(comprobante))
      unless response[:fex_result_auth].present?
        messages = response[:fex_err][:err_msg]
        raise Afiper::Error, [messages].flatten.to_json
      end
      cae = response[:fex_result_auth][:cae]
      fch_vto = response[:fex_result_auth][:fch_venc_cae]
      comprobante.update_attributes(cae: cae, vencimiento_cae: fch_vto, afip_result: response.to_json)
      true
    end

    def parameters(comprobante)
      ret = atributos_basicos(comprobante)
      if comprobante.comprobante_asociado.present?
        ret[:Cmp][:Cmps_asoc] = {
          Cmp_asoc: {
            Cbte_tipo: comprobante.comprobante_asociado.config[:codigo_afip],
            Cbte_punto_vta: comprobante.comprobante_asociado.punto_de_venta,
            Cbte_nro: comprobante.comprobante_asociado.numero,
            Cbte_cuit: comprobante.comprobante_asociado.emisor_cuit
          }
        }
      else
        ret[:Cmp][:Fecha_pago] = comprobante.fecha.strftime('%Y%m%d')
      end
      ret
    end

    def atributos_basicos(comprobante)
      id = Rails.env.test? ? rand(5000000000) : 100_000_000 + comprobante.id
      {
        Cmp: {
          Id: id,
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
    end

    # def autorizar_o_actualizar(comprobante)
    #   autorizar_comprobante(comprobante)
    # rescue AfipWsError => error_original
    #   if error_original.error_code == '1535' # Si no es el próximo a autorizar
    #     begin
    #       actualizar_comprobante(comprobante)
    #     rescue Error
    #       raise error_original
    #     end
    #   else
    #     raise error_original
    #   end
    # end

    # def get_cmp(comprobante)
    #   @comprobante = comprobante # No borrar
    #   get_cmp_det(comprobante.tipo.to_sym, comprobante.punto_de_venta, comprobante.numero)
    # end

    # def actualizar_comprobante(comprobante)
    #   res = get_cmp(comprobante)
    #   comprobante.update_attributes!(cae: res[:cod_autorizacion], vencimiento_cae: res[:fch_vto]) # TODO: tal vez agregar afip_result?
    # end

    # def get_cmp_det(tipo, punto_de_venta, numero)
    #   validar_tipo(tipo)
    #   tipo_afip = Comprobante.find_config(:nombre, tipo)[:codigo_afip]
    #   response = call_auth(:fex_get_cmp,
    #                   Cmp: {
    #                     Tipo_cbte: tipo_afip,
    #                     Punto_vta: punto_de_venta,
    #                     Cbte_nro: numero,
    #                   })
    #   # TODO: no se pudo probar en homologacion
    #   response[:result_get]
    # end

    # def ultimo_cmp(tipo_cbte, punto_de_venta)
    #   validar_tipo(tipo_cbte)
    #   tipo_afip = Comprobante.find_config(:nombre, tipo_cbte)[:codigo_afip]
    #   response = call_auth(:fex_get_last_cmp,
    #                Auth: {
    #                  Pto_venta: punto_de_venta,
    #                  Tipo_cbte: tipo_afip,
    #                }
    #              )
    #   response[:fex_result_last_cmp][:cbte_nro].to_i
    # end

    # def validar_tipo(tipo)
    #   return unless Comprobante.find_config(:nombre, tipo).nil?

    #   raise Afiper::Error, "Tipo erróneo #{tipo}"
    # end
  end
end
