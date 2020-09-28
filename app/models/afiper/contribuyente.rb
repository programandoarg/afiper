# frozen_string_literal: true

# == Schema Information
#
# Table name: afiper_contribuyentes
#
#  id                            :bigint           not null, primary key
#  razon_social                  :string           not null
#  cuit                          :string           not null
#  iibb                          :string           not null
#  inicio_actividades            :date             not null
#  condicion_iva                 :integer          not null
#  domicilio                     :string           not null
#  afip_certificado              :string
#  afip_clave                    :string
#  afip_certificado_homologacion :string
#  afip_clave_homologacion       :string
#  service_wsfe                  :boolean          default(FALSE), not null
#  service_padron                :boolean          default(FALSE), not null
#  puntos_de_venta               :json             not null
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#

require 'afiper/application_record'

module Afiper
  # Datos del contribuyente y claves para acceder a la API de la AFIP
  class Contribuyente < ApplicationRecord
    has_many :comprobantes, class_name: 'Afiper::Comprobante', foreign_key: :afiper_contribuyente_id

    validates :razon_social, :cuit, :iibb, :inicio_actividades, presence: true
    enum condicion_iva: { iva_responsable_inscripto: 0, monotributo: 1 }

    def self.for_wsfe
      where(service_wsfe: true).first
    end

    def self.for_padron
      where(service_padron: true).first
    end

    def wsfe_client
      if Afiper.configuration.wsfe_homologacion
        WsfeClient.new(cuit, afip_clave_homologacion, afip_certificado_homologacion)
      else
        WsfeClient.new(cuit, afip_clave, afip_certificado)
      end
    end

    def wsfex_client
      if Afiper.configuration.wsfe_homologacion
        WsfexClient.new(cuit, afip_clave_homologacion, afip_certificado_homologacion)
      else
        WsfexClient.new(cuit, afip_clave, afip_certificado)
      end
    end

    def default_punto_de_venta(tipo)
      puntos_de_venta[tipo]
    end

    def proximo_numero(tipo, punto_de_venta)
      # wsfe_client.ultimo_cmp(tipo, punto_de_venta) + 1
      last = comprobantes.where(tipo: tipo, punto_de_venta: punto_de_venta).order(:numero).last
      (last.try(:numero) || 0) + 1
    end

    def tipos_de_comprobante_que_emite
      Comprobante.configuracion_tipos.select do |t|
        t[:nombre].in?(%i[factura_a nota_de_credito_a nota_de_debito_a
                          factura_b nota_de_credito_b nota_de_debito_b
                          ticket_no_fiscal devolucion_no_fiscal
                          factura_e nota_de_credito_e nota_de_debito_e])
      end
    end

    def afip_configured?(homologacion)
      if homologacion
        afip_certificado_homologacion.present? && afip_clave_homologacion.present?
      else
        afip_certificado.present? && afip_clave.present?
      end
    end
  end
end
