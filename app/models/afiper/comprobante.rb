module Afiper
  class Comprobante < ActiveRecord::Base
    ALICUOTAS = [
        { desc: '21%', tipo_afip: 5, perc_iva: 21 },
        { desc: '10.5%', tipo_afip: 4, perc_iva: 10.5 },
        { desc: '5%', tipo_afip: 8, perc_iva: 5 },
        { desc: '27%', tipo_afip: 6, perc_iva: 27 },
        { desc: '2.5%', tipo_afip: 9, perc_iva: 2.5 },
        { desc: '0%', tipo_afip: 3, perc_iva: 0 },
      ]

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

    before_validation do |comprobante|
      comprobante.concepto = 1 unless comprobante.concepto.present?
      comprobante.mon_id = 'PES' unless comprobante.mon_id.present?
      comprobante.mon_cotiz = 1 unless comprobante.mon_cotiz.present?
      comprobante.numero = contribuyente.proximo_numero(comprobante.tipo.to_sym, comprobante.punto_de_venta)
    end

    def total
      subtotal_no_gravado + subtotal_exento + subtotal_gravado + subtotal_iva + subtotal_tributos
    end

    def subtotal_gravado
      iva_3_base_imponible + iva_4_base_imponible + iva_5_base_imponible + iva_6_base_imponible + iva_8_base_imponible + iva_9_base_imponible
    end

    def subtotal_iva
      iva_3_importe + iva_4_importe + iva_5_importe + iva_6_importe + iva_8_importe + iva_9_importe
    end

    def subtotal_tributos
      0 # TODO
    end

    def tipo_afip
      TIPOS_AFIP[tipo]
    end

    def alicuotas
      ALICUOTAS.map do |alicuota|
        {
          base_imponible: self["iva_#{alicuota[:tipo_afip]}_base_imponible"],
          importe: self["iva_#{alicuota[:tipo_afip]}_importe"],
          tipo_afip: alicuota[:tipo_afip]
        }
      end.select { |alicuota| alicuota[:base_imponible] > 0 }
    end
  end
end
