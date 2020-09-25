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
FactoryBot.define do
  factory :afiper_item, class: 'Afiper::Item' do
    # tipo { Afiper::Item::DEFAULT_TIPO }
    # percepcion_iva {}
    codigo { rand(1..1000) }
    detalle { Faker::Lorem.sentence }
    cantidad { rand(1..20) }
    importe { rand(1..10_000) }
  end
end
