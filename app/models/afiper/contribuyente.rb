module Afiper
  class Contribuyente < ActiveRecord::Base
    has_many :comprobantes, class_name: 'Afiper::Comprobante', foreign_key: :afiper_contribuyente_id

    validates :razon_social, :cuit, :iibb, :inicio_actividades, presence: true
    enum condicion_iva: { iva_responsable_inscripto: 0, monotributo: 1 }

    def self.for_wsfe
      self.where(service_wsfe: true).first
    end

    def self.for_padron
      self.where(service_padron: true).first
    end

    def wsfe_client
      WsfeClient.new(self)
    end

    def default_punto_de_venta(tipo)
      puntos_de_venta[tipo]
    end

    def proximo_numero(tipo, punto_de_venta)
      # wsfe_client.ultimo_cmp(tipo, punto_de_venta) + 1
      last = comprobantes.where(tipo: Comprobante.tipos[tipo], punto_de_venta: punto_de_venta).order(:numero).last
      (last.try(:numero) || 0) + 1
    end

    def tipos_de_comprobante_que_emite
      Comprobante.configuracion_tipos.select do |t|
        t[:nombre].in?([:factura_a, :nota_de_credito_a, :nota_de_debito_a, :recibo_a,
          :factura_b, :nota_de_credito_b, :nota_de_debito_b, :recibo_b,
          :ticket_no_fiscal, :devolucion_no_fiscal])
      end
    end
  end
end
