# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_09_23_174849) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "afiper_comprobantes", force: :cascade do |t|
    t.bigint "afiper_contribuyente_id", null: false
    t.bigint "comprobante_asociado_id", null: false
    t.integer "tipo", null: false
    t.date "fecha", null: false
    t.integer "punto_de_venta", null: false
    t.integer "numero", null: false
    t.date "emisor_inicio_actividades", null: false
    t.string "emisor_cuit", null: false
    t.string "emisor_iibb", null: false
    t.string "emisor_razon_social", null: false
    t.integer "receptor_doc_tipo", null: false
    t.string "receptor_doc_nro", null: false
    t.string "receptor_razon_social", null: false
    t.integer "receptor_condicion_iva", null: false
    t.integer "condicion_venta", null: false
    t.bigint "receptor_codigo_pais"
    t.bigint "receptor_cuit_pais"
    t.string "receptor_domicilio"
    t.string "exportacion_id_impositivo"
    t.integer "concepto", null: false
    t.integer "moneda", default: 0, null: false
    t.float "moneda_cotizacion", default: 1.0, null: false
    t.date "fecha_servicio_desde"
    t.date "fecha_servicio_hasta"
    t.date "fecha_vencimiento_pago"
    t.boolean "creado_por_el_sistema", null: false
    t.boolean "fiscal", null: false
    t.string "cae"
    t.date "vencimiento_cae"
    t.string "afip_result"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["afiper_contribuyente_id"], name: "index_afiper_comprobantes_on_afiper_contribuyente_id"
    t.index ["comprobante_asociado_id"], name: "index_afiper_comprobantes_on_comprobante_asociado_id"
  end

  create_table "afiper_contribuyentes", force: :cascade do |t|
    t.string "razon_social", null: false
    t.string "cuit", null: false
    t.string "iibb", null: false
    t.date "inicio_actividades", null: false
    t.integer "condicion_iva", null: false
    t.string "domicilio", null: false
    t.string "afip_certificado"
    t.string "afip_clave"
    t.string "afip_certificado_homologacion"
    t.string "afip_clave_homologacion"
    t.boolean "service_wsfe", default: false, null: false
    t.boolean "service_padron", default: false, null: false
    t.json "puntos_de_venta", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "afiper_items", force: :cascade do |t|
    t.bigint "afiper_comprobante_id", null: false
    t.integer "tipo", null: false
    t.decimal "percepcion_iva", null: false
    t.string "codigo", null: false
    t.string "detalle", null: false
    t.integer "cantidad", default: 1, null: false
    t.decimal "importe", precision: 15, scale: 2, null: false
    t.decimal "descuento", precision: 15, scale: 2, default: "0.0", null: false
    t.decimal "recargo", precision: 15, scale: 2, default: "0.0", null: false
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["afiper_comprobante_id"], name: "index_afiper_items_on_afiper_comprobante_id"
  end

  create_table "afiper_wsaa_tokens", force: :cascade do |t|
    t.bigint "afiper_contribuyente_id", null: false
    t.string "token", null: false
    t.string "sign", null: false
    t.string "cuit", null: false
    t.string "service", null: false
    t.boolean "homologacion", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["afiper_contribuyente_id"], name: "index_afiper_wsaa_tokens_on_afiper_contribuyente_id"
  end

  add_foreign_key "afiper_comprobantes", "afiper_comprobantes", column: "comprobante_asociado_id"
  add_foreign_key "afiper_comprobantes", "afiper_contribuyentes"
  add_foreign_key "afiper_items", "afiper_comprobantes"
  add_foreign_key "afiper_wsaa_tokens", "afiper_contribuyentes"
end
