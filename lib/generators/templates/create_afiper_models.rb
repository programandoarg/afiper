class CreateAfiperModels < ActiveRecord::Migration
  def change
    create_table :afiper_contribuyentes do |t|
      t.string :razon_social, null: false
      t.string :cuit, null: false
      t.string :iibb, null: false
      t.date :inicio_actividades, null: false
      t.integer :condicion_iva, null: false
      t.string :domicilio, null: false

      t.string :afip_certificado
      t.string :afip_clave
      t.string :afip_certificado_homologacion
      t.string :afip_clave_homologacion


      t.json :puntos_de_venta, default: {}, null: false

      t.timestamps null: false
    end

    create_table :afiper_comprobantes do |t|
      t.references :afiper_contribuyente, null: false, foreign_key: true, index: true

      t.integer :tipo, null: false
      t.date :fecha, null: false
      t.integer :punto_de_venta, null: false
      t.integer :numero, null: false

      t.date :emisor_inicio_actividades, null: false
      t.string :emisor_cuit, null: false
      t.string :emisor_iibb, null: false
      t.string :emisor_razon_social, null: false

      t.integer :receptor_doc_tipo, null: false
      t.string :receptor_doc_nro, null: false
      t.string :receptor_razon_social, null: false
      t.integer :receptor_condicion_iva, null: false

      t.integer :condicion_venta, null: false

      t.integer :concepto, null: false
      t.string :mon_id, null: false
      t.integer :mon_cotiz, null: false

      # t.decimal :subtotal_no_gravado,     precision: 15, scale: 2, null: false, default: 0.0
      # t.decimal :subtotal_exento,         precision: 15, scale: 2, null: false, default: 0.0

      # t.decimal :neto_gravado_3,  precision: 15, scale: 2, null: false, default: 0.0
      # t.decimal :neto_gravado_4,  precision: 15, scale: 2, null: false, default: 0.0
      # t.decimal :neto_gravado_5,  precision: 15, scale: 2, null: false, default: 0.0
      # t.decimal :neto_gravado_6,  precision: 15, scale: 2, null: false, default: 0.0
      # t.decimal :neto_gravado_8,  precision: 15, scale: 2, null: false, default: 0.0
      # t.decimal :neto_gravado_9,  precision: 15, scale: 2, null: false, default: 0.0

      t.date :fecha_servicio_desde
      t.date :fecha_servicio_hasta
      t.date :fecha_vencimiento_pago

      t.boolean :creado_por_el_sistema, null: false
      t.boolean :fiscal, null: false

      t.string :cae
      t.date :vencimiento_cae
      t.string :afip_result # JSON que retorna la API al solicitar CAE, se guarda por las dudas

      t.timestamps null: false
    end

    create_table :afiper_items do |t|
      t.references :afiper_comprobante, null: false, foreign_key: true, index: true
      t.integer :tipo, null: false
      t.decimal :percepcion_iva, null: false

      t.string :codigo, null: false
      t.string :detalle, null: false
      t.integer :cantidad, null: false, default: 1
      t.decimal :importe, precision: 15, scale: 2, null: false
      t.integer :descuento, default: 0, null: false

      t.timestamps null: false
    end

    create_table :afiper_wsaa_tokens do |t|
      t.references :afiper_contribuyente, null: false, foreign_key: true, index: true

      t.string :token, null: false
      t.string :sign, null: false
      t.string :cuit, null: false
      t.string :service, null: false
      t.boolean :homologacion, null: false

      t.timestamps null: false
    end
  end
end
