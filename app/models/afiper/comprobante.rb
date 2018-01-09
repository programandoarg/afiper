module Afiper
  class Comprobante < ActiveRecord::Base
    TIPOS_AFIP = {
      factura_a: 1,
      factura_b: 6,
      factura_c: 11,
      nota_de_credito_a: 3,
      nota_de_credito_b: 8,
      nota_de_credito_c: 13,
      nota_de_debito_a: 2,
      nota_de_debito_b: 7,
      nota_de_debito_c: 12,
      recibo_a: 4,
      recibo_b: 9,
    }

    enum tipo: [
      :factura_a, :factura_b, :factura_c,
      :nota_de_credito_a, :nota_de_credito_b, :nota_de_credito_c,
      :nota_de_debito_a, :nota_de_debito_b, :nota_de_debito_c,
      :recibo_a, :recibo_b
    ]

    belongs_to :contribuyente, class_name: 'Afiper::Contribuyente', foreign_key: :afiper_contribuyente_id
    has_many :items, class_name: 'Afiper::Item', foreign_key: :afiper_comprobante_id

    before_create do |comprobante|
      comprobante.concepto = 1 unless comprobante.concepto.present? # Productos
      comprobante.mon_id = 'PES' unless comprobante.mon_id.present?
      comprobante.mon_cotiz = 1 unless comprobante.mon_cotiz.present?
      comprobante.emisor_inicio_actividades = comprobante.contribuyente.inicio_actividades unless comprobante.emisor_inicio_actividades.present?
      comprobante.emisor_cuit = comprobante.contribuyente.cuit unless comprobante.emisor_cuit.present?
      comprobante.emisor_iibb = comprobante.contribuyente.iibb unless comprobante.emisor_iibb.present?
      comprobante.numero = comprobante.contribuyente.proximo_numero(comprobante.tipo.to_sym, comprobante.punto_de_venta) unless comprobante.numero.present?
    end


    # Validaciones

    def validate_total
      return if items?
      errors[:base] << 'El comprobante debe tener al menos un renglón'
    end


    # Totales

    def subtotal_no_gravado
      items.no_gravado.sum('cantidad * importe')
    end

    def subtotal_exento
      items.exento.sum('cantidad * importe')
    end

    def subtotal_gravado
      items.gravado.sum('cantidad * importe')
    end

    def total
      subtotal_no_gravado + subtotal_exento + subtotal_gravado + subtotal_iva + subtotal_tributos
    end

    def subtotal_iva
      items.gravado.sum('round(cantidad * importe * 0.01 * percepcion_iva, 2)')
    end

    def subtotal_tributos
      0 # TODO
    end

    def tipo_afip
      TIPOS_AFIP[tipo.to_sym]
    end

    def alicuotas
      items.gravado.group_by(&:tipo).map do |k, v|
        {
          base_imponible: v.map { |e| (e.cantidad * e.importe).round(2) }.sum.to_f
          importe: v.map { |e| (e.cantidad * e.importe * 0.01 * Item.tipos[k][:percepcion_iva]).round(2) }.sum.to_f
          codigo_alicuota: Item.tipos[k][:codigo_alicuota]
        }
      end.select { |alicuota| alicuota[:base_imponible] > 0 }
    end

    def solicitar_cae
      contribuyente.wsfe_client.solicitar_cae(self)
    end

    def actualizar_comprobante
      contribuyente.wsfe_client.actualizar_comprobante(self)
    end

    def readonly?
      persisted? && cae_was.present?
    end
  end
end
