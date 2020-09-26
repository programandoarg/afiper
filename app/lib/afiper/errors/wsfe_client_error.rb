# frozen_string_literal: true

module Afiper
  module Errors
    class WsfeClientError < StandardError
      def initialize(original_message)
        @original_message = original_message
      end

      def error_code
        original_json[0]["code"]
      end

      def original_json
        JSON.parse(@original_message)
      end

      def message
        case error_code
        when '10013'
          'Para comprobantes tipo A y M se debe ingresar un CUIT'
        when '10049'
          'Debe ingresar las fechas de servicio'
        when '10016'
          # comprobante = Afiper::Comprobante.find(params_hash[:comprobante_id])
          # "El comprobante número #{comprobante.numero} no es el próximo a autorizar para el punto de venta #{comprobante.punto_de_venta}"
          "El comprobante número no es el próximo a autorizar para el punto de venta"
        when '10015'
          'El documento (CUIT, DNI, etc) no es válido'
        else
          original_json[0]["message"] || 'Error al conectar con el sistema de la AFIP'
        end
      end
    end
  end
end
