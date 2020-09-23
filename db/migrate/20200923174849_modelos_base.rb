class ModelosBase < ActiveRecord::Migration[5.2]
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

      t.boolean :service_wsfe, null: false, default: false
      t.boolean :service_padron, null: false, default: false


      t.json :puntos_de_venta, default: {}, null: false

      t.timestamps null: false
    end

    create_table :afiper_comprobantes do |t|
      t.references :afiper_contribuyente, null: false, foreign_key: true, index: true
      t.references :comprobante_asociado, null: false, index: true

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

      t.bigint :receptor_codigo_pais
      t.bigint :receptor_cuit_pais
      t.string :receptor_domicilio
      t.string :exportacion_id_impositivo

      t.integer :concepto, null: false
      t.integer :moneda, null: false, default: 0
      t.float :moneda_cotizacion, null: false, default: 1.0

      t.date :fecha_servicio_desde
      t.date :fecha_servicio_hasta
      t.date :fecha_vencimiento_pago

      t.boolean :creado_por_el_sistema, null: false
      t.boolean :fiscal, null: false

      t.string :cae
      t.date :vencimiento_cae
      t.string :afip_result # JSON que retorna la API al solicitar CAE, se guarda por las dudas

      t.datetime :deleted_at

      t.timestamps null: false
    end

    add_foreign_key :afiper_comprobantes, :afiper_comprobantes, column: :comprobante_asociado_id

    create_table :afiper_items do |t|
      t.references :afiper_comprobante, null: false, foreign_key: true, index: true
      t.integer :tipo, null: false
      t.decimal :percepcion_iva, null: false

      t.string :codigo, null: false
      t.string :detalle, null: false
      t.integer :cantidad, null: false, default: 1
      t.decimal :importe, precision: 15, scale: 2, null: false
      t.decimal :descuento, precision: 15, scale: 2, null: false, default: 0
      t.decimal :recargo, precision: 15, scale: 2, null: false, default: 0

      t.datetime :deleted_at

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
