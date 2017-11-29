class CreateAsyncRequest < ActiveRecord::Migration
  def change
    create_table :afiper_comprobantes do |t|
      t.date :fecha, null: false
      t.integer :punto_de_venta, null: false
      t.integer :numero, null: false
      t.integer :tipo, null: false

      t.date :emisor_inicio_actividades, null: false
      t.string :emisor_cuit, null: false
      t.string :emisor_iibb, null: false

      t.integer :receptor_doc_tipo, null: false
      t.string :receptor_doc_nro, null: false
      t.string :receptor_razon_social, null: false

      t.integer :concepto, null: false
      t.string :mon_id, null: false
      t.integer :mon_cotiz, null: false

      t.decimal :total_no_gravado,     precision: 15, scale: 2, null: false, default: 0
      t.decimal :total_exento,         precision: 15, scale: 2, null: false, default: 0

      # t.decimal :imp_total, precision: 15, scale: 2, null: false
      # t.decimal :imp_neto, precision: 15, scale: 2, null: false
      # t.decimal :imp_trib, precision: 15, scale: 2, null: false
      # t.decimal :imp_iva, precision: 15, scale: 2, null: false

      t.decimal :iva_3_base_imponible,  precision: 15, scale: 2, null: false, default: 0
      t.decimal :iva_3_importe,         precision: 15, scale: 2, null: false, default: 0
      t.decimal :iva_4_base_imponible,  precision: 15, scale: 2, null: false, default: 0
      t.decimal :iva_4_importe,         precision: 15, scale: 2, null: false, default: 0
      t.decimal :iva_5_base_imponible,  precision: 15, scale: 2, null: false, default: 0
      t.decimal :iva_5_importe,         precision: 15, scale: 2, null: false, default: 0
      t.decimal :iva_6_base_imponible,  precision: 15, scale: 2, null: false, default: 0
      t.decimal :iva_6_importe,         precision: 15, scale: 2, null: false, default: 0
      t.decimal :iva_8_base_imponible,  precision: 15, scale: 2, null: false, default: 0
      t.decimal :iva_8_importe,         precision: 15, scale: 2, null: false, default: 0
      t.decimal :iva_9_base_imponible,  precision: 15, scale: 2, null: false, default: 0
      t.decimal :iva_9_importe,         precision: 15, scale: 2, null: false, default: 0

      t.string :cae
      t.date :vencimiento_cae
      t.string :afip_result

      t.timestamps null: false
    end
  end
end
