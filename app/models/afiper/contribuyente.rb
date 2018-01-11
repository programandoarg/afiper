module Afiper
  class Contribuyente < ActiveRecord::Base
    has_many :comprobantes, class_name: 'Afiper::Comprobante', foreign_key: :afiper_contribuyente_id

    validates :razon_social, :cuit, :iibb, :inicio_actividades, presence: true

    def wsfe_client
      WsfeClient.new(self)
    end

    def default_punto_de_venta(tipo)
      {
        factura_a: 33,
        factura_b: 33,
        factura_c: 33,
        nota_de_credito_a: 33,
        nota_de_credito_b: 33,
        nota_de_credito_c: 33,
        nota_de_debito_a: 33,
        nota_de_debito_b: 33,
        nota_de_debito_c: 33,
        recibo_a: 33,
        recibo_b: 33,
        ticket_no_fiscal: 1,
        devolucion_no_fiscal: 1,
      }[tipo.to_sym]
    end

    def proximo_numero(tipo, punto_de_venta)
      # wsfe_client.ultimo_cmp(tipo, punto_de_venta) + 1
      last = comprobantes.where(tipo: Comprobante.tipos[tipo], punto_de_venta: punto_de_venta).order(:numero).last
      (last.try(:numero) || 0) + 1
    end
  end
end
