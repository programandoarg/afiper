module Afiper
  class Contribuyente < ActiveRecord::Base
    has_many :comprobantes, class_name: 'Afiper::Comprobante', foreign_key: :afiper_contribuyente_id

    def wsfe_client
      WsfeClient.new(self)
    end

    def proximo_numero(tipo, punto_de_venta)
      wsfe_client.ultimo_cmp(tipo, punto_de_venta) + 1
    end
  end
end
