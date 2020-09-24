# frozen_string_literal: true

# == Schema Information
#
# Table name: afiper_comprobantes
#
#  id                        :bigint           not null, primary key
#  afiper_contribuyente_id   :bigint           not null
#  comprobante_asociado_id   :bigint           not null
#  tipo                      :integer          not null
#  fecha                     :date             not null
#  punto_de_venta            :integer          not null
#  numero                    :integer          not null
#  emisor_inicio_actividades :date             not null
#  emisor_cuit               :string           not null
#  emisor_iibb               :string           not null
#  emisor_razon_social       :string           not null
#  receptor_doc_tipo         :integer          not null
#  receptor_doc_nro          :string           not null
#  receptor_razon_social     :string           not null
#  receptor_condicion_iva    :integer          not null
#  condicion_venta           :integer          not null
#  receptor_codigo_pais      :bigint
#  receptor_cuit_pais        :bigint
#  receptor_domicilio        :string
#  exportacion_id_impositivo :string
#  concepto                  :integer          not null
#  moneda                    :integer          default("pesos"), not null
#  moneda_cotizacion         :float            default(1.0), not null
#  fecha_servicio_desde      :date
#  fecha_servicio_hasta      :date
#  fecha_vencimiento_pago    :date
#  creado_por_el_sistema     :boolean          not null
#  fiscal                    :boolean          not null
#  cae                       :string
#  vencimiento_cae           :date
#  afip_result               :string
#  deleted_at                :datetime
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#
require 'rails_helper'

RSpec.describe Afiper::Comprobante do
  it do
    described_class.new
  end
end
