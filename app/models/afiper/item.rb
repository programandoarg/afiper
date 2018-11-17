module Afiper
  class Item < ActiveRecord::Base
    class << self
      def tipos_for_select
        tipos.map { |k, v| [v[:descripcion], k] }
      end

      def tipos
        {
          0 => { descripcion: '21%',         codigo_alicuota: 5,    percepcion_iva: 21    },
          1 => { descripcion: '10.5%',       codigo_alicuota: 4,    percepcion_iva: 10.5  },
          2 => { descripcion: '5%',          codigo_alicuota: 8,    percepcion_iva: 5     },
          3 => { descripcion: '27%',         codigo_alicuota: 6,    percepcion_iva: 27    },
          4 => { descripcion: '2.5%',        codigo_alicuota: 9,    percepcion_iva: 2.5   },
          5 => { descripcion: '0%',          codigo_alicuota: 3,    percepcion_iva: 0     },
          6 => { descripcion: 'No gravado',  codigo_alicuota: nil,  percepcion_iva: nil   },
          7 => { descripcion: 'Exento',      codigo_alicuota: nil,  percepcion_iva: nil   }
        }
      end

      def tipo_from_afip(tipo_afip)
        tipos.find {|k,v| v[:codigo_alicuota] == tipo_afip.to_i }.first
      end
    end

    DEFAULT_TIPO = 6 # No gravado

    belongs_to :comprobante, class_name: 'Afiper::Comprobante', foreign_key: :afiper_comprobante_id

    scope :gravado, -> { where(tipo: [0..5]) }
    scope :no_gravado, -> { where(tipo: 6) }
    scope :exento, -> { where(tipo: 7) }

    before_save :set_percepcion_iva

    def set_percepcion_iva
      self.tipo = DEFAULT_TIPO unless tipo.present?
      self.percepcion_iva = if Item.tipos[tipo][:percepcion_iva].present?
                              Item.tipos[tipo][:percepcion_iva]
                            else
                              0
                            end
    end

    def descuento_porcentaje
      return 0 unless importe.present? && importe > 0
      (100 * descuento / importe).round(2)
    end

    def recargo_porcentaje
      return 0 unless importe.present? && importe > 0
      (100 * recargo / importe).round(2)
    end

    def subtotal
      # cantidad * importe
      return 0 unless importe.present? && descuento.present? && recargo.present?
      cantidad * (importe - descuento + recargo)
    end

    def total
      cantidad * (importe - descuento + recargo)
    end

    def importe_neto
      if comprobante.config[:adicionar_iva]
        importe - descuento + recargo
      else
        (importe - descuento + recargo) / multiplicador_iva
      end
    end

    # def total_mas_iva
    #   total * multiplicador_iva
    # end

    # def importe_mas_iva
    #   return unless importe.present?
    #   (importe * multiplicador_iva).round(2)
    # end

    def multiplicador_iva
      return 1.0 unless percepcion_iva.present?
      1 + 0.01 * percepcion_iva
    end

    def readonly?
      persisted? && comprobante.cae.present?
    end
  end
end
