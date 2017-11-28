class CreateAsyncRequest < ActiveRecord::Migration
  def change
    create_table :afiper_comprobantes do |t|
      t.integer :punto_de_venta, null: false
      t.integer :numero, null: false
      t.integer :tipo, null: false
      t.date :fecha, null: false
      t.string :cae
      t.date :vencimiento_cae
      t.string :afip_result
      t.integer :concepto, null: false
      t.integer :doc_tipo, null: false
      t.string :doc_nro, null: false
      t.decimal :imp_total, precision: 15, scale: 2, null: false
      t.decimal :imp_tot_conc, precision: 15, scale: 2, null: false
      t.decimal :imp_neto, precision: 15, scale: 2, null: false
      t.decimal :imp_op_ex, precision: 15, scale: 2, null: false
      t.decimal :imp_trib, precision: 15, scale: 2, null: false
      t.decimal :imp_iva, precision: 15, scale: 2, null: false
      t.string :mon_id, null: false
      t.integer :mon_cotiz, null: false
      
      t.timestamps null: false
    end
  end
end
