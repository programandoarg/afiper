# frozen_string_literal: true

module Afiper
  class Error < StandardError; end

  # Timeout o error de conexión
  class ErrorTemporal < Error
    attr_accessor :original_exception

    def initialize(msg = '', original_exception = nil)
      self.original_exception = original_exception
      ret = +'Por favor intente nuevamente más tarde.'
      if msg.present?
        ret << " Detalle del error: #{msg}"
      end
      super(ret)
    end
  end

  # Error enviado por el Web Service de la AFIP
  class AfipWsError < Error
    attr_reader :original_messages

    def initialize(messages)
      @original_messages = [messages].flatten
      super(build_message)
    end

    def first_message
      ActiveSupport::HashWithIndifferentAccess.new @original_messages[0]
    end

    def error_code
      first_message['code']
    end

    def error_message
      "(#{error_code}) #{first_message['msg']}"
    end

    def build_message
      case error_code
      when '10013'
        'Para comprobantes tipo A y M se debe ingresar un CUIT'
      when '10049'
        'Debe ingresar las fechas de servicio'
      when '1580'
        'Debe informar el CUIT del pais destino'
      when '1560'
        'Debe informar el código del pais destino'
      when '1661'
        'Debe informar el domicilio del cliente'
      when '1535'
        "El comprobante número no es el próximo a autorizar para el punto de venta"
      when '10016'
        # TODO:
        # comprobante = Afiper::Comprobante.find(params_hash[:comprobante_id])
        # "El comprobante número #{comprobante.numero} no es el próximo a autorizar para el punto de venta #{comprobante.punto_de_venta}"
        "El comprobante número no es el próximo a autorizar para el punto de venta"
      when '10015'
        'El documento (CUIT, DNI, etc) no es válido'
      else
        error_message
      end
    end
  end
end
