class CambioEnumCondicionIva < ActiveRecord::Migration[5.2]
  def change
    Afiper::Comprobante.where(receptor_condicion_iva: 2).update_all(receptor_condicion_iva: 5)
    Afiper::Comprobante.where(receptor_condicion_iva: 0).update_all(receptor_condicion_iva: 4)
    Afiper::Comprobante.where(receptor_condicion_iva: 1).update_all(receptor_condicion_iva: 0)
  end
end
