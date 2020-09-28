class CrearWsaaTokens < ActiveRecord::Migration[5.2]
  def change
    create_table :afiper_wsaa_tokens do |t|
      t.string :token, null: false
      t.string :sign, null: false
      t.string :cuit, null: false
      t.string :service, null: false
      t.boolean :homologacion, null: false

      t.timestamps null: false
    end
  end
end
