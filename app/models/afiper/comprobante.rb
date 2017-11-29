module Afiper
  class Comprobante < ActiveRecord::Base
    belongs_to :contribuyente

    before_validation do |comprobante|
      comprobante.concepto = 1 unless comprobante.concepto.present?
      comprobante.mon_id = 'PES' unless comprobante.mon_id.present?
      comprobante.mon_cotiz = 1 unless comprobante.mon_cotiz.present?
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
  end
end
