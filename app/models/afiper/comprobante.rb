module Afiper
  class Comprobante < ActiveRecord::Base
    class << self
      def configuracion_tipos
        [
          { id: 1,  nombre: :factura_a,            descripcion: 'Factura A',              codigo_afip: 1,    nombre_print: 'FACTURA',          letra: 'A', multiplicador_saldo:  1 },
          { id: 2,  nombre: :factura_b,            descripcion: 'Factura B',              codigo_afip: 6,    nombre_print: 'FACTURA',          letra: 'B', multiplicador_saldo:  1 },
          { id: 3,  nombre: :factura_c,            descripcion: 'Factura C',              codigo_afip: 11,   nombre_print: 'FACTURA',          letra: 'C', multiplicador_saldo:  1 },
          { id: 4,  nombre: :nota_de_credito_a,    descripcion: 'Nota de crédito A',      codigo_afip: 3,    nombre_print: 'NOTA DE CREDITO',  letra: 'A', multiplicador_saldo: -1 },
          { id: 5,  nombre: :nota_de_credito_b,    descripcion: 'Nota de crédito B',      codigo_afip: 8,    nombre_print: 'NOTA DE CREDITO',  letra: 'B', multiplicador_saldo: -1 },
          { id: 6,  nombre: :nota_de_credito_c,    descripcion: 'Nota de crédito C',      codigo_afip: 13,   nombre_print: 'NOTA DE CREDITO',  letra: 'C', multiplicador_saldo: -1 },
          { id: 7,  nombre: :nota_de_debito_a,     descripcion: 'Nota de débito A',       codigo_afip: 2,    nombre_print: 'NOTA DE DEBITO',   letra: 'A', multiplicador_saldo:  1 },
          { id: 8,  nombre: :nota_de_debito_b,     descripcion: 'Nota de débito B',       codigo_afip: 7,    nombre_print: 'NOTA DE DEBITO',   letra: 'B', multiplicador_saldo:  1 },
          { id: 9,  nombre: :nota_de_debito_c,     descripcion: 'Nota de débito C',       codigo_afip: 12,   nombre_print: 'NOTA DE DEBITO',   letra: 'C', multiplicador_saldo:  1 },
          { id: 10, nombre: :recibo_a,             descripcion: 'Recibo A',               codigo_afip: 4,    nombre_print: 'RECIBO',           letra: 'A', multiplicador_saldo:  0 },
          { id: 11, nombre: :recibo_b,             descripcion: 'Recibo B',               codigo_afip: 9,    nombre_print: 'RECIBO',           letra: 'B', multiplicador_saldo:  0 },
          { id: 12, nombre: :ticket_no_fiscal,     descripcion: 'Ticket no fiscal',     codigo_afip: nil,  nombre_print: 'COMPROBANTE NO VALIDO COMO FACTURA',          letra: 'X', multiplicador_saldo:  1 },
          { id: 13, nombre: :devolucion_no_fiscal, descripcion: 'Devolución no fiscal', codigo_afip: nil,  nombre_print: 'COMPROBANTE NO VALIDO COMO FACTURA',          letra: 'X', multiplicador_saldo: -1 },
        ]
      end

      def find_config(key, value)
        configuracion_tipos.find {|tipo| tipo[key] == value }
      end

      def build(params)
        comprobante = new(params)
        comprobante.contribuyente = Afiper::Contribuyente.first unless comprobante.contribuyente.present?
        comprobante.punto_de_venta = comprobante.contribuyente.default_punto_de_venta(comprobante.tipo) unless comprobante.punto_de_venta.present?
        comprobante.contado = false unless comprobante.contado.present?
        comprobante.creado_por_el_sistema = true unless comprobante.creado_por_el_sistema.present?
        comprobante.numero = comprobante.contribuyente.proximo_numero(comprobante.tipo.to_sym, comprobante.punto_de_venta)
        comprobante
      end
    end

    def config
      Comprobante.find_config(:nombre, tipo.to_sym)
    end

    enum concepto: { productos: 1, servicios: 2, productos_y_servicios: 3 }

    enum tipo: Comprobante.configuracion_tipos.map { |config| [config[:nombre], config[:id]] }.to_h

    belongs_to :contribuyente, class_name: 'Afiper::Contribuyente', foreign_key: :afiper_contribuyente_id
    has_many :items, class_name: 'Afiper::Item', foreign_key: :afiper_comprobante_id
    accepts_nested_attributes_for :items, allow_destroy: true

    before_create do |comprobante|
      comprobante.concepto = :productos unless comprobante.concepto.present? # Productos
      comprobante.mon_id = 'PES' unless comprobante.mon_id.present?
      comprobante.mon_cotiz = 1 unless comprobante.mon_cotiz.present?
      comprobante.emisor_inicio_actividades = comprobante.contribuyente.inicio_actividades unless comprobante.emisor_inicio_actividades.present?
      comprobante.emisor_cuit = comprobante.contribuyente.cuit unless comprobante.emisor_cuit.present?
      comprobante.emisor_iibb = comprobante.contribuyente.iibb unless comprobante.emisor_iibb.present?
      comprobante.numero = comprobante.contribuyente.proximo_numero(comprobante.tipo.to_sym, comprobante.punto_de_venta) unless comprobante.numero.present?
      comprobante.receptor_doc_tipo = 99 unless comprobante.receptor_doc_tipo.present?
      comprobante.receptor_doc_nro = 0 unless comprobante.receptor_doc_nro.present?
      comprobante.receptor_razon_social = 'Consumidor final' unless comprobante.receptor_razon_social.present?
      comprobante.fiscal = comprobante.fiscal?
      true
    end


    # Validaciones
    validates :punto_de_venta, :numero, :tipo, :fecha, presence: true
    validates :contado, inclusion: { in: [true, false] }

    def autorizado?
      cae.present?
    end

    def fiscal?
      config[:codigo_afip].present?
    end

    def tiene_servicios?
      concepto.in?(['servicios', 'productos_y_servicios'])
    end

    def pventa_numero
      "#{pventa_formatted} - #{numero_formatted}"
    end

    def pventa_formatted
      punto_de_venta.to_s.rjust(4, '0')
    end

    def numero_formatted
      numero.to_s.rjust(8, '0')
    end

    # Totales

    def subtotal_no_gravado
      items.no_gravado.sum('cantidad * importe')
    end

    def subtotal_exento
      items.exento.sum('cantidad * importe')
    end

    def subtotal_gravado
      items.gravado.sum('cantidad * importe')
    end

    def total
      subtotal_no_gravado + subtotal_exento + subtotal_gravado + subtotal_iva + subtotal_tributos
    end

    def subtotal_iva
      items.gravado.sum('round(cantidad * importe * 0.01 * percepcion_iva, 2)')
    end

    def subtotal_tributos
      0 # TODO
    end

    def concepto_afip
      # El enum tiene los valores correspondientes de la afip
      self['concepto']
    end

    def alicuotas
      items.gravado.group_by(&:tipo).map do |k, v|
        {
          base_imponible: v.map { |e| (e.cantidad * e.importe).round(2) }.sum.to_f,
          importe: v.map { |e| (e.cantidad * e.importe * 0.01 * Item.tipos[k][:percepcion_iva]).round(2) }.sum.to_f,
          codigo_alicuota: Item.tipos[k][:codigo_alicuota],
        }
      end.select { |alicuota| alicuota[:base_imponible] > 0 }
    end

    def solicitar_cae
      contribuyente.wsfe_client.solicitar_cae(self)
    end

    def actualizar_comprobante
      contribuyente.wsfe_client.actualizar_comprobante(self)
    end

    def readonly?
      persisted? && cae_was.present?
    end
  end
end





# module Afiper
#   module ComprobanteConfig
#     def letra_matchers
#       [
#         TipoMatcher.new('factura_a', 'A'),
#         TipoMatcher.new('factura_b', 'B'),
#         TipoMatcher.new('recibo_a', 'A'),
#         DefaultMatcher.new('X'),
#       ]
#     end

#     # def tipo_cbte_matchers
#     #   [
#     #     TipoMatcher.new('factura_a', 1),
#     #     TipoMatcher.new('factura_b', 6),
#     #     TipoMatcher.new('nota_de_credito', 3),
#     #     TipoMatcher.new('recibo', 4),
#     #   ]
#     # end

#     # def default_punto_de_venta_matchers
#     #   oficial = comercio.config['punto_venta_oficial']
#     #   no_oficial = comercio.config['punto_venta_no_oficial']
#     #   unless oficial.present? && no_oficial.present?
#     #     fail CustomApplicationError, '"Punto de venta" no está configurado'
#     #   end
#     #   [
#     #     TipoMatcher.new('Pago', no_oficial),
#     #     TipoMatcher.new('Presupuesto', no_oficial),
#     #     DefaultMatcher.new(oficial),
#     #   ]
#     # end

#     # def evaluate_should_afip_sync_matchers
#     #   pventa = comercio.config['punto_venta_oficial']
#     #   [
#     #     # TipoMatcher.new('Pago', false),
#     #     # TipoMatcher.new('Presupuesto', false),
#     #     TipoPuntoVentaMatcher.new('nota_de_credito', pventa, true),
#     #     TipoPuntoVentaMatcher.new('factura_a', pventa, true),
#     #     TipoPuntoVentaMatcher.new('factura_b', pventa, true),
#     #     TipoPuntoVentaMatcher.new('recibo', pventa, true),
#     #     DefaultMatcher.new(false),
#     #   ]
#     # end

#     # def can_be_contado_matchers
#     #   [
#     #     TipoMatcher.new('nota_de_credito', true),
#     #     TipoMatcher.new('recibo', false),
#     #     TipoMatcher.new('factura', true),
#     #     DefaultMatcher.new(false),
#     #   ]
#     # end

#     # def nombre_print_matchers
#     #   [
#     #     # TipoMatcher.new('Presupuesto', 'FACTURA'),
#     #     TipoMatcher.new('factura', 'FACTURA'),
#     #     TipoMatcher.new('nota_de_credito', 'NOTA DE CREDITO'),
#     #     TipoMatcher.new('recibo', 'recibo'),
#     #   ]
#     # end

#     # def tipo_abbr_matchers
#     #   [
#     #     TipoMatcher.new('Presupuesto', 'PRES'),
#     #     TipoMatcher.new('Pago', 'PAGO'),
#     #     TipoMatcher.new('factura_a', 'FAA'),
#     #     TipoMatcher.new('factura_b', 'FAB'),
#     #     TipoMatcher.new('nota_de_credito', 'NC'),
#     #     TipoMatcher.new('recibo', 'RECA'),
#     #   ]
#     # end

#     # def nombre_para_mail_matchers
#     #   nombre_print_matchers
#     # end

#     def can_be_consumidor_final_matchers
#       [
#         TipoMatcher.new('nota_de_credito', false),
#         TipoMatcher.new('factura_b', true),
#         TipoMatcher.new('recibo', true),
#         DefaultMatcher.new(false),
#       ]
#     end

#     def multiplicador_saldo_matchers
#       [
#         TipoMatcher.new('factura', 1),
#         TipoMatcher.new('recibo', -1),
#         TipoMatcher.new('nota_de_credito', -1),
#       ]
#     end

#     # def detalle_impuestos_matchers
#     #   [
#     #     TipoMatcher.new('nota_de_credito', true),
#     #     TipoMatcher.new('factura_a', true),
#     #     DefaultMatcher.new(false),
#     #   ]
#     # end

#     def form_element_matchers
#       [
#         FormElementMatcher.new('factura_b', [:articulo, :iva, :cantidad, :sumar_iva, :hide_iva_on_show]),
#         # FormElementMatcher.new('Presupuesto', [:articulo, :cantidad]),
#         FormElementMatcher.new('nota_de_credito', [:articulo, :iva, :cantidad]),
#         FormElementMatcher.new('factura', [:articulo, :iva, :cantidad]),
#         FormElementMatcher.new('recibo', [:tipo_de_pago]),
#         DefaultMatcher.new(false),
#       ]
#     end

#     def method_missing(name, *args, &block)
#       method_name = "#{name}_matchers"
#       super unless self.respond_to?(method_name)
#       matchers = self.send(method_name)
#       value_for(self, matchers, args)
#     end

#     def value_for(comprobante, matchers, args)
#       matchers.each do |matcher|
#         return matcher.value if matcher.match?(comprobante, args)
#       end
#       raise 'las cosas'
#     end
#   end
# end



# [{:id=>"1", :desc=>"factura A", :fch_desde=>"20100917", :fch_hasta=>"NULL"},
#  {:id=>"2", :desc=>"Nota de Débito A", :fch_desde=>"20100917", :fch_hasta=>"NULL"},
#  {:id=>"3", :desc=>"Nota de Crédito A", :fch_desde=>"20100917", :fch_hasta=>"NULL"},
#  {:id=>"6", :desc=>"factura B", :fch_desde=>"20100917", :fch_hasta=>"NULL"},
#  {:id=>"7", :desc=>"Nota de Débito B", :fch_desde=>"20100917", :fch_hasta=>"NULL"},
#  {:id=>"8", :desc=>"Nota de Crédito B", :fch_desde=>"20100917", :fch_hasta=>"NULL"},
#  {:id=>"4", :desc=>"recibos A", :fch_desde=>"20100917", :fch_hasta=>"NULL"},
#  {:id=>"5", :desc=>"Notas de Venta al contado A", :fch_desde=>"20100917", :fch_hasta=>"NULL"},
#  {:id=>"9", :desc=>"recibos B", :fch_desde=>"20100917", :fch_hasta=>"NULL"},
#  {:id=>"10", :desc=>"Notas de Venta al contado B", :fch_desde=>"20100917", :fch_hasta=>"NULL"},
#  {:id=>"63", :desc=>"Liquidacion A", :fch_desde=>"20100917", :fch_hasta=>"NULL"},
#  {:id=>"64", :desc=>"Liquidacion B", :fch_desde=>"20100917", :fch_hasta=>"NULL"},
#  {:id=>"34", :desc=>"Cbtes. A del Anexo I, Apartado A,inc.f),R.G.Nro. 1415", :fch_desde=>"20100917", :fch_hasta=>"NULL"},
#  {:id=>"35", :desc=>"Cbtes. B del Anexo I,Apartado A,inc. f),R.G. Nro. 1415", :fch_desde=>"20100917", :fch_hasta=>"NULL"},
#  {:id=>"39", :desc=>"Otros comprobantes A que cumplan con R.G.Nro. 1415", :fch_desde=>"20100917", :fch_hasta=>"NULL"},
#  {:id=>"40", :desc=>"Otros comprobantes B que cumplan con R.G.Nro. 1415", :fch_desde=>"20100917", :fch_hasta=>"NULL"},
#  {:id=>"60", :desc=>"Cta de Vta y Liquido prod. A", :fch_desde=>"20100917", :fch_hasta=>"NULL"},
#  {:id=>"61", :desc=>"Cta de Vta y Liquido prod. B", :fch_desde=>"20100917", :fch_hasta=>"NULL"},
#  {:id=>"11", :desc=>"factura C", :fch_desde=>"20110330", :fch_hasta=>"NULL"},
#  {:id=>"12", :desc=>"Nota de Débito C", :fch_desde=>"20110330", :fch_hasta=>"NULL"},
#  {:id=>"13", :desc=>"Nota de Crédito C", :fch_desde=>"20110330", :fch_hasta=>"NULL"},
#  {:id=>"15", :desc=>"recibo C", :fch_desde=>"20110330", :fch_hasta=>"NULL"},
#  {:id=>"49", :desc=>"Comprobante de Compra de Bienes Usados a Consumidor Final", :fch_desde=>"20130401", :fch_hasta=>"NULL"},
#  {:id=>"51", :desc=>"factura M", :fch_desde=>"20150522", :fch_hasta=>"NULL"},
#  {:id=>"52", :desc=>"Nota de Débito M", :fch_desde=>"20150522", :fch_hasta=>"NULL"},
#  {:id=>"53", :desc=>"Nota de Crédito M", :fch_desde=>"20150522", :fch_hasta=>"NULL"},
#  {:id=>"54", :desc=>"recibo M", :fch_desde=>"20150522", :fch_hasta=>"NULL"}]
