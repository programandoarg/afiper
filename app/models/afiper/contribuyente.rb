module Afiper
  class Contribuyente < ActiveRecord::Base
    has_many :comprobantes, class_name: 'Afiper::Comprobante', foreign_key: :afiper_contribuyente_id

    validates :razon_social, :cuit, :iibb, :inicio_actividades, presence: true

    def wsfe_client
      WsfeClient.new(self)
    end

    def proximo_numero(tipo, punto_de_venta)
      # wsfe_client.ultimo_cmp(tipo, punto_de_venta) + 1
      last = comprobantes.where(tipo: Comprobante.tipos[tipo], punto_de_venta: punto_de_venta).order(:numero).last
      (last.try(:numero) || 0) + 1
    end
  end
end
