# frozen_string_literal: true

# == Schema Information
#
# Table name: afiper_items
#
#  id                    :bigint           not null, primary key
#  afiper_comprobante_id :bigint           not null
#  tipo                  :integer          not null
#  percepcion_iva        :decimal(, )      not null
#  codigo                :string           not null
#  detalle               :string           not null
#  cantidad              :integer          default(1), not null
#  importe               :decimal(15, 2)   not null
#  descuento             :decimal(15, 2)   default(0.0), not null
#  recargo               :decimal(15, 2)   default(0.0), not null
#  deleted_at            :datetime
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#

require 'afiper/application_record'

module Afiper
  # Cada una de las líneas de un comprobante
  class Item < ApplicationRecord
    class << self
      def tipos_for_select
        tipos.select { |k,v| [0, 1, 3, 7].include?(k) }.map { |k, v| [v[:descripcion], k] }
      end

      def tipos
        # TODO: agregar un tipo "No indicado" para tipo C? o si no que sea nullable?
        # Este nuevo tipo tendría que estar incluido en el scope "gravado"
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
        tipos.find { |_k, v| v[:codigo_alicuota] == tipo_afip.to_i }.first
      end
    end

    belongs_to :comprobante, class_name: 'Afiper::Comprobante',
                             foreign_key: :afiper_comprobante_id, inverse_of: :items, optional: true

    acts_as_paranoid without_default_scope: true

    scope :gravado, -> { where(tipo: [0..5]) }
    scope :no_gravado, -> { where(tipo: 6) }
    scope :exento, -> { where(tipo: 7) }

    before_save :set_percepcion_iva

    validate :importe_positivo
    validate :importe_mayor_a_descuento

    def importe_positivo
      return if importe.positive? && descuento >= 0 && cantidad.positive?

      errors.add(:base, 'El importe no puede ser negativo')
    end

    def importe_mayor_a_descuento
      return if importe > descuento

      errors.add(:base, 'El descuento no puede ser mayor al importe')
    end

    def set_percepcion_iva
      self.tipo = default_tipo_iva unless tipo.present?
      self.percepcion_iva = if Item.tipos[tipo][:percepcion_iva].present?
                              Item.tipos[tipo][:percepcion_iva]
                            else
                              0
                            end
    end

    def default_tipo_iva
      if comprobante.present?
        comprobante.default_tipo_iva
      else
        6 # No gravado
      end
    end

    def descuento_porcentaje
      return 0 unless importe.present? && importe.positive?

      (100 * descuento / importe).round(2)
    end

    def recargo_porcentaje
      return 0 unless importe.present? && importe.positive?

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

    def importe_alicuota
      (cantidad * importe_neto * 0.01 * percepcion_iva).round(2)
    end

    def total_neto
      (cantidad * importe_neto).round(2)
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
