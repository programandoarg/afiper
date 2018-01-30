module Afiper
  class Comprobante < ActiveRecord::Base
    class << self
      def configuracion_tipos
        [
          { id: 1,  nombre: :factura_a,            descripcion: 'Factura A',                   codigo_afip: 1,    nombre_print: 'FACTURA',                             letra: 'A', multiplicador_saldo:  1, tiene_iva: true,  adicionar_iva: true,  recibo: false },
          { id: 2,  nombre: :factura_b,            descripcion: 'Factura B',                   codigo_afip: 6,    nombre_print: 'FACTURA',                             letra: 'B', multiplicador_saldo:  1, tiene_iva: true,  adicionar_iva: false, recibo: false },
          { id: 3,  nombre: :factura_c,            descripcion: 'Factura C',                   codigo_afip: 11,   nombre_print: 'FACTURA',                             letra: 'C', multiplicador_saldo:  1, tiene_iva: true,  adicionar_iva: false, recibo: false },
          { id: 4,  nombre: :nota_de_credito_a,    descripcion: 'Nota de crédito A',           codigo_afip: 3,    nombre_print: 'NOTA DE CREDITO',                     letra: 'A', multiplicador_saldo: -1, tiene_iva: true,  adicionar_iva: true,  recibo: false },
          { id: 5,  nombre: :nota_de_credito_b,    descripcion: 'Nota de crédito B',           codigo_afip: 8,    nombre_print: 'NOTA DE CREDITO',                     letra: 'B', multiplicador_saldo: -1, tiene_iva: true,  adicionar_iva: false, recibo: false },
          { id: 6,  nombre: :nota_de_credito_c,    descripcion: 'Nota de crédito C',           codigo_afip: 13,   nombre_print: 'NOTA DE CREDITO',                     letra: 'C', multiplicador_saldo: -1, tiene_iva: true,  adicionar_iva: false, recibo: false },
          { id: 7,  nombre: :nota_de_debito_a,     descripcion: 'Nota de débito A',            codigo_afip: 2,    nombre_print: 'NOTA DE DEBITO',                      letra: 'A', multiplicador_saldo:  1, tiene_iva: true,  adicionar_iva: true,  recibo: false },
          { id: 8,  nombre: :nota_de_debito_b,     descripcion: 'Nota de débito B',            codigo_afip: 7,    nombre_print: 'NOTA DE DEBITO',                      letra: 'B', multiplicador_saldo:  1, tiene_iva: true,  adicionar_iva: false, recibo: false },
          { id: 9,  nombre: :nota_de_debito_c,     descripcion: 'Nota de débito C',            codigo_afip: 12,   nombre_print: 'NOTA DE DEBITO',                      letra: 'C', multiplicador_saldo:  1, tiene_iva: true,  adicionar_iva: false, recibo: false },
          { id: 10, nombre: :recibo_a,             descripcion: 'Recibo A',                    codigo_afip: 4,    nombre_print: 'RECIBO',                              letra: 'A', multiplicador_saldo:  0, tiene_iva: true,  adicionar_iva: true,  recibo: true  },
          { id: 11, nombre: :recibo_b,             descripcion: 'Recibo B',                    codigo_afip: 9,    nombre_print: 'RECIBO',                              letra: 'B', multiplicador_saldo:  0, tiene_iva: true,  adicionar_iva: false, recibo: true  },
          { id: 12, nombre: :ticket_no_fiscal,     descripcion: 'Ticket no fiscal',            codigo_afip: nil,  nombre_print: '',                                    letra: 'X', multiplicador_saldo:  1, tiene_iva: false, adicionar_iva: false, recibo: false },
          { id: 13, nombre: :devolucion_no_fiscal, descripcion: 'Nota de crédito no fiscal',   codigo_afip: nil,  nombre_print: '',                                    letra: 'X', multiplicador_saldo: -1, tiene_iva: false, adicionar_iva: false, recibo: false },
        ]
      end

      def configuracion_doc_tipos
        [
          { id: 1,  nombre: :cuit,                      descripcion: "CUIT",                    codigo_afip: "80" },
          { id: 2,  nombre: :cuil,                      descripcion: "CUIL",                    codigo_afip: "86" },
          { id: 3,  nombre: :cdi,                       descripcion: "CDI",                     codigo_afip: "87" },
          { id: 4,  nombre: :le,                        descripcion: "LE",                      codigo_afip: "89" },
          { id: 5,  nombre: :lc,                        descripcion: "LC",                      codigo_afip: "90" },
          { id: 6,  nombre: :ci_extranjera,             descripcion: "CI Extranjera",           codigo_afip: "91" },
          { id: 7,  nombre: :en_tramite,                descripcion: "en trámite",              codigo_afip: "92" },
          { id: 8,  nombre: :acta_nacimiento,           descripcion: "Acta Nacimiento",         codigo_afip: "93" },
          { id: 9,  nombre: :ci_bs_as_rnp,              descripcion: "CI Bs. As. RNP",          codigo_afip: "95" },
          { id: 10, nombre: :dni,                       descripcion: "DNI",                     codigo_afip: "96" },
          { id: 11, nombre: :pasaporte,                 descripcion: "Pasaporte",               codigo_afip: "94" },
          { id: 12, nombre: :ci_policia_federal,        descripcion: "CI Policía Federal",      codigo_afip: "0"  },
          { id: 13, nombre: :ci_buenos_aires,           descripcion: "CI Buenos Aires",         codigo_afip: "1"  },
          { id: 14, nombre: :ci_catamarca,              descripcion: "CI Catamarca",            codigo_afip: "2"  },
          { id: 15, nombre: :ci_cordoba,                descripcion: "CI Córdoba",              codigo_afip: "3"  },
          { id: 16, nombre: :ci_corrientes,             descripcion: "CI Corrientes",           codigo_afip: "4"  },
          { id: 17, nombre: :ci_entre_rios,             descripcion: "CI Entre Ríos",           codigo_afip: "5"  },
          { id: 18, nombre: :ci_jujuy,                  descripcion: "CI Jujuy",                codigo_afip: "6"  },
          { id: 19, nombre: :ci_mendoza,                descripcion: "CI Mendoza",              codigo_afip: "7"  },
          { id: 20, nombre: :ci_la_rioja,               descripcion: "CI La Rioja",             codigo_afip: "8"  },
          { id: 21, nombre: :ci_salta,                  descripcion: "CI Salta",                codigo_afip: "9"  },
          { id: 22, nombre: :ci_san_juan,               descripcion: "CI San Juan",             codigo_afip: "10" },
          { id: 23, nombre: :ci_san_luis,               descripcion: "CI San Luis",             codigo_afip: "11" },
          { id: 24, nombre: :ci_santa_fe,               descripcion: "CI Santa Fe",             codigo_afip: "12" },
          { id: 25, nombre: :ci_santiago_del_estero,    descripcion: "CI Santiago del Estero",  codigo_afip: "13" },
          { id: 26, nombre: :ci_tucuman,                descripcion: "CI Tucumán",              codigo_afip: "14" },
          { id: 27, nombre: :ci_chaco,                  descripcion: "CI Chaco",                codigo_afip: "16" },
          { id: 28, nombre: :ci_chubut,                 descripcion: "CI Chubut",               codigo_afip: "17" },
          { id: 29, nombre: :ci_formosa,                descripcion: "CI Formosa",              codigo_afip: "18" },
          { id: 30, nombre: :ci_misiones,               descripcion: "CI Misiones",             codigo_afip: "19" },
          { id: 31, nombre: :ci_neuquen,                descripcion: "CI Neuquén",              codigo_afip: "20" },
          { id: 32, nombre: :ci_la_pampa,               descripcion: "CI La Pampa",             codigo_afip: "21" },
          { id: 33, nombre: :ci_rio_negro,              descripcion: "CI Río Negro",            codigo_afip: "22" },
          { id: 34, nombre: :ci_santa_cruz,             descripcion: "CI Santa Cruz",           codigo_afip: "23" },
          { id: 35, nombre: :ci_tierra_del_fuego,       descripcion: "CI Tierra del Fuego",     codigo_afip: "24" },
          { id: 36, nombre: :doc_otro,                  descripcion: "Doc. (Otro)",             codigo_afip: "99" },
        ]
      end

      def find_config(key, value)
        configuracion_tipos.find { |tipo| tipo[key] == value }
      end

      def build(params)
        comprobante = new(params)
        comprobante.contribuyente = Afiper::Contribuyente.first unless comprobante.contribuyente.present?
        comprobante.punto_de_venta = comprobante.contribuyente.default_punto_de_venta(comprobante.tipo) unless comprobante.punto_de_venta.present?
        comprobante.creado_por_el_sistema = true unless comprobante.creado_por_el_sistema.present?
        comprobante.numero = comprobante.contribuyente.proximo_numero(comprobante.tipo.to_sym, comprobante.punto_de_venta)
        comprobante.fecha = Time.zone.today
        comprobante.fecha_servicio_desde = Time.zone.today
        comprobante.fecha_servicio_hasta = Time.zone.today
        comprobante.fecha_vencimiento_pago = Time.zone.today
        if comprobante.config[:recibo]
          comprobante.concepto = :servicios
        end
        comprobante
      end
    end

    def config
      Comprobante.find_config(:nombre, tipo.to_sym)
    end

    def receptor_doc_tipo_values
      Comprobante.configuracion_doc_tipos.find { |tipo| tipo[:nombre] == receptor_doc_tipo.to_sym }
    end

    enum concepto: { productos: 1, servicios: 2, productos_y_servicios: 3 }
    enum receptor_condicion_iva: { consumidor_final: 0, responsable_inscripto: 1, monotributo: 2 }
    enum condicion_venta: { contado: 0 }

    enum tipo: Comprobante.configuracion_tipos.map { |config| [config[:nombre], config[:id]] }.to_h
    enum receptor_doc_tipo: Comprobante.configuracion_doc_tipos.map { |config| [config[:nombre], config[:id]] }.to_h

    belongs_to :contribuyente, class_name: 'Afiper::Contribuyente', foreign_key: :afiper_contribuyente_id
    has_many :items, class_name: 'Afiper::Item', foreign_key: :afiper_comprobante_id, dependent: :destroy
    accepts_nested_attributes_for :items, allow_destroy: true

    before_create do |comprobante|
      comprobante.concepto = :productos unless comprobante.concepto.present? # Productos
      comprobante.mon_id = 'PES' unless comprobante.mon_id.present?
      comprobante.mon_cotiz = 1 unless comprobante.mon_cotiz.present?
      comprobante.emisor_razon_social = comprobante.contribuyente.razon_social unless comprobante.emisor_razon_social.present?
      comprobante.emisor_inicio_actividades = comprobante.contribuyente.inicio_actividades unless comprobante.emisor_inicio_actividades.present?
      comprobante.emisor_cuit = comprobante.contribuyente.cuit unless comprobante.emisor_cuit.present?
      comprobante.emisor_iibb = comprobante.contribuyente.iibb unless comprobante.emisor_iibb.present?
      comprobante.numero = comprobante.contribuyente.proximo_numero(comprobante.tipo.to_sym, comprobante.punto_de_venta) unless comprobante.numero.present?
      if comprobante.receptor_doc_tipo.nil? && comprobante.receptor_doc_nro.nil?
        comprobante.receptor_doc_tipo = :doc_otro
        comprobante.receptor_doc_nro = 0
        comprobante.receptor_razon_social = 'Consumidor final'
      end
      comprobante.fiscal = comprobante.fiscal?
      comprobante.condicion_venta = 0 unless comprobante.condicion_venta.present?
      comprobante.receptor_condicion_iva = 0 unless comprobante.receptor_condicion_iva.present?
      true
    end


    # Validaciones
    validates :punto_de_venta, :numero, :tipo, :fecha, :receptor_razon_social, presence: true

    # def receptor_condicion_iva
    #   'Consumidor final'
    # end

    def receptor_domicilio
      '-'
    end

    # def condicion_venta
    #   'CONTADO'
    # end

    def conceptos_posibles
      if config[:recibo]
        Afiper::Comprobante.conceptos.select { |k,v| k == 'servicios'}
      else
        Afiper::Comprobante.conceptos
      end
    end

    def consmumidor_final?
      # byebug
      receptor_doc_tipo == 'doc_otro'
    end

    def autorizado?
      cae.present?
    end

    def mostrar_iva?
      config[:tiene_iva] && config[:adicionar_iva]
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
      if config[:tiene_iva] && !config[:adicionar_iva]
        items.gravado.sum('round(cantidad * (importe / (1 + 0.01 * percepcion_iva)), 2)')
      else
        items.gravado.sum('cantidad * importe')
      end
    end

    def total
      if config[:adicionar_iva]
        items.sum('round(cantidad * importe * (1 + 0.01 * percepcion_iva), 2)')
        # items.sum('cantidad * importe') # Faltarían los tributos
      else
        items.sum('round(cantidad * importe, 2)')
        # subtotal_no_gravado + subtotal_exento + subtotal_gravado + subtotal_iva + subtotal_tributos
      end
      # if config[:ingresar_con_iva]
      #   items.sum('cantidad * importe') # Faltarían los tributos
      # else
      #   subtotal_no_gravado + subtotal_exento + subtotal_gravado + subtotal_iva + subtotal_tributos
      # end
    end

    def subtotal_iva
      if config[:adicionar_iva]
        items.gravado.sum('round(cantidad * importe * 0.01 * percepcion_iva, 2)')
      else
        items.gravado.sum('round(cantidad * (importe - (importe / (1 + 0.01 * percepcion_iva))), 2)')
      end
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
          base_imponible: v.map { |e| (e.cantidad * e.importe_neto).round(2) }.sum.to_f,
          importe: v.map { |e| (e.cantidad * e.importe_neto * 0.01 * Item.tipos[k][:percepcion_iva]).round(2) }.sum.to_f,
          codigo_alicuota: Item.tipos[k][:codigo_alicuota],
          descripcion: Item.tipos[k][:descripcion],
        }
      end.select { |alicuota| alicuota[:base_imponible] > 0 }
    end

    def solicitar_cae
      contribuyente.wsfe_client.solicitar_cae(self)
    end

    def actualizar_comprobante
      contribuyente.wsfe_client.actualizar_comprobante(self)
    end

    def barcode
      return unless autorizado?
      Barby::Code25Interleaved.new(barcode_data)
    end

    def barcode_data
      data = payload
      data << verificador(data)
      data
    end

    def verificador(data)
      # 2012079182701000466217207571810201606053
      array = data.scan(/\w/)
      odds = array.values_at(* array.each_index.select {|i| i.even? }).map(&:to_i)
      evens = array.values_at(* array.each_index.select {|i| i.odd? }).map(&:to_i)
      odds_sum = odds.inject(0) { |sum, x| sum + x }
      evens_sum = evens.inject(0) { |sum, x| sum + x }
      ((10 - ((odds_sum * 3 + evens_sum) % 10)) % 10).to_s
    end

    def payload
      data = ''
      data << emisor_cuit.to_s
      data << config[:codigo_afip].to_s.rjust(2, '0')
      data << punto_de_venta.to_s.rjust(4, '0')
      data << cae.to_s.rjust(14, '0')
      data << vencimiento_cae.strftime('%Y%m%d')
      data
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
