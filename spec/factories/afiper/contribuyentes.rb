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
FactoryBot.define do
  factory :afiper_contribuyente, class: 'Afiper::Contribuyente' do
    razon_social { Faker::Lorem.sentence }
    cuit { '20123456780' }
    iibb { '20123456780' }
    inicio_actividades { Faker::Date.backward }
    condicion_iva { 0 }
    domicilio { Faker::Lorem.sentence }
    puntos_de_venta { {} }
  end
end
