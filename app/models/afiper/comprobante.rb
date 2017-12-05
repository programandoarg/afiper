module Afiper
  class Comprobante < ActiveRecord::Base
    ALICUOTAS = {
      3 => { desc: '0%', codigo_alicuota: 3, perc_iva: 0 },
      4 => { desc: '10.5%', codigo_alicuota: 4, perc_iva: 10.5 },
      5 => { desc: '21%', codigo_alicuota: 5, perc_iva: 21 },
      6 => { desc: '27%', codigo_alicuota: 6, perc_iva: 27 },
      8 => { desc: '5%', codigo_alicuota: 8, perc_iva: 5 },
      9 => { desc: '2.5%', codigo_alicuota: 9, perc_iva: 2.5 },
    }

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

    before_create do |comprobante|
      comprobante.concepto = 1 unless comprobante.concepto.present? # Productos
      comprobante.mon_id = 'PES' unless comprobante.mon_id.present?
      comprobante.mon_cotiz = 1 unless comprobante.mon_cotiz.present?
      comprobante.emisor_inicio_actividades = comprobante.contribuyente.inicio_actividades unless comprobante.emisor_inicio_actividades.present?
      comprobante.emisor_cuit = comprobante.contribuyente.cuit unless comprobante.emisor_cuit.present?
      comprobante.emisor_iibb = comprobante.contribuyente.iibb unless comprobante.emisor_iibb.present?
      comprobante.numero = comprobante.contribuyente.proximo_numero(comprobante.tipo.to_sym, comprobante.punto_de_venta) unless comprobante.numero.present?
    end

    def total
      subtotal_no_gravado + subtotal_exento + subtotal_gravado + subtotal_iva + subtotal_tributos
    end

    def subtotal_gravado
      iva_base_imponible(3) + iva_base_imponible(4) + iva_base_imponible(5) + iva_base_imponible(6) + iva_base_imponible(8) + iva_base_imponible(9)
    end

    def subtotal_iva
      iva_importe(3) + iva_importe(4) + iva_importe(5) + iva_importe(6) + iva_importe(8) + iva_importe(9)
    end

    def iva_base_imponible(codigo_alicuota)
      self["neto_gravado_#{alicuota[:codigo_alicuota]}"]
    end

    def iva_importe(codigo_alicuota)
      alicuota = ALICUOTAS[codigo_alicuota]
      (iva_base_imponible(codigo_alicuota) * alicuota[:perc_iva] * 0.01).round(2)
    end

    def subtotal_tributos
      0 # TODO
    end

    def tipo_afip
      TIPOS_AFIP[tipo.to_sym]
    end

    def alicuotas
      ALICUOTAS.map do |alicuota|
        {
          base_imponible: iva_base_imponible(alicuota[:codigo_alicuota]),
          importe: iva_importe(alicuota[:codigo_alicuota]),
          codigo_alicuota: alicuota[:codigo_alicuota]
        }
      end.select { |alicuota| alicuota[:base_imponible] > 0 }
    end
  end
end
