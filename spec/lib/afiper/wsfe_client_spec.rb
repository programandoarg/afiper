require 'rails_helper'

describe Afiper::WsfeClient do
  let(:contribuyente) do
    create :afiper_contribuyente,
      cuit: ENV['AFIP_CUIT'],
      afip_certificado: ENV['AFIP_CERTIFICADO'],
      afip_clave: ENV['AFIP_CLAVE'],
      afip_certificado_homologacion: ENV['AFIP_CERTIFICADO'],
      afip_clave_homologacion: ENV['AFIP_CLAVE']
  end
  let(:instancia) { described_class.new(contribuyente) }

  let(:item) { build :afiper_item, cantidad: 1, importe: 300 }
  let(:pventa) { 1 }
  let(:numero) { 2 }
  let(:receptor_doc_tipo) { 1 } # CUIT
  let(:receptor_doc_nro) { '20120791827' }
  let(:comprobante) do
    create :afiper_comprobante, tipo_comprobante: :factura_a, items: [item], numero: numero,
                                receptor_doc_tipo: receptor_doc_tipo, punto_de_venta: pventa,
                                receptor_doc_nro: receptor_doc_nro, fecha: Date.today
  end

  describe '#autorizar_comprobante' do
    subject(:autorizar_comprobante) { instancia.autorizar_comprobante(comprobante) }

    context 'cuando autoriza correctamente', vcr_cassettes: ['solicitar_cae', 'wsaa']  do
      it { is_expected.to be_truthy }
    end

    context 'cuando hace falta el CUIT', vcr_cassettes: ['solicitar_cae_falta_cuit', 'wsaa'] do
      let(:numero) { 3 }
      let(:receptor_doc_tipo) { 2 } # CUIL
      
      it { expect { autorizar_comprobante }.to raise_error having_attributes(error_code: "10013") }
      it { expect { autorizar_comprobante }.to raise_error /se debe ingresar un CUIT/i }
    end

    context 'cuando el cuit no es válido', vcr_cassettes: ['solicitar_cae_cuit_invalido', 'wsaa'] do
      let(:numero) { 3 }
      let(:receptor_doc_nro) { '1' }
      
      it { expect { autorizar_comprobante }.to raise_error having_attributes(error_code: "10015") }
      it { expect { autorizar_comprobante }.to raise_error /El documento .* no es válido/i }
    end

    context 'cuando hace falta fecha de servicio',
            vcr_cassettes: ['solicitar_cae_falta_fecha_servicio', 'wsaa'] do
      let(:numero) { 3 }
      let(:comprobante) do
        create :afiper_comprobante, tipo_comprobante: :factura_a, items: [item], numero: numero,
                                    receptor_doc_tipo: receptor_doc_tipo, punto_de_venta: pventa,
                                    receptor_doc_nro: receptor_doc_nro, fecha: Date.today,
                                    concepto: :servicios
      end
      
      it { expect { autorizar_comprobante }.to raise_error having_attributes(error_code: '10049') }
      it { expect { autorizar_comprobante }.to raise_error /Debe ingresar las fechas de servicio/i }
    end
  end

  describe '#autorizar_o_actualizar' do
    subject(:autorizar_o_actualizar) { instancia.autorizar_o_actualizar(comprobante) }
    
    context 'cuando no es el próximo a autorizar', vcr_cassettes: ['solicitar_cae_fail', 'wsaa'] do
      let(:numero) { 656 }
      
      it { expect { autorizar_o_actualizar }.to raise_error having_attributes(error_code: "10016") }
      it { expect { autorizar_o_actualizar }.to raise_error /no es el próximo a autorizar/i }
    end

    context 'cuando ya fue autorizado', vcr_cassettes: ['solicitar_cae_ya_autorizado', 'wsaa'] do
      let(:numero) { 1 }
      
      it { is_expected.to be_truthy }
      it { autorizar_o_actualizar; expect(comprobante).to be_autorizado }
    end
  end

  describe '#get_tipos_cbte', vcr_cassettes: ['get_tipos_cbte', 'wsaa'] do
    subject { instancia.get_tipos_cbte.length }
    
    it { is_expected.to eq 36 }
  end

  describe '#ultimo_cmp', vcr_cassettes: ['ultimo_cmp', 'wsaa'] do
    subject { instancia.ultimo_cmp(:factura_a, 1) }
    
    it { is_expected.to eq 0 }
  end
end
