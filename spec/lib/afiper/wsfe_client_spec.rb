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

  describe '#ultimo_cmp', vcr_cassettes: ['ultimo_cmp', 'wsaa'] do
    subject { instancia.ultimo_cmp(:factura_a, 1) }
    
    it { is_expected.to eq 0 }
  end

  describe '#solicitar_cae', vcr_cassettes: ['solicitar_cae', 'wsaa'] do
    let(:item) { build :afiper_item, cantidad: 1, importe: 300 }
    let(:pventa) { 1 }
    let(:numero) { 2 }
    let(:comprobante) do
      create :afiper_comprobante, tipo_comprobante: :factura_a, items: [item],
                                  numero: numero, receptor_doc_tipo: 1, punto_de_venta: pventa,
                                  receptor_doc_nro: '20120791827', fecha: Date.today
    end
    subject { instancia.solicitar_cae(comprobante) }
    
    it { is_expected.to be_truthy }

    context 'cuando no es el próximo a autorizar', vcr_cassettes: ['solicitar_cae_fail', 'wsaa'] do
      let(:numero) { 656 }
      
      it { expect { subject }.to raise_error having_attributes(error_code: "10016") }
      it { expect { subject }.to raise_error /no es el próximo a autorizar/i }
    end

    context 'cuando ya fue autorizado', vcr_cassettes: ['solicitar_cae_ya_autorizado', 'wsaa'] do
      let(:numero) { 1 }
      
      it { is_expected.to be_truthy }
      it { subject; expect(comprobante).to be_autorizado }
    end
  end

  describe '#get_tipos_cbte', vcr_cassettes: ['get_tipos_cbte', 'wsaa'] do
    subject { instancia.get_tipos_cbte.length }
    
    it { is_expected.to eq 36 }
  end

  describe '#auth_hash', vcr_cassettes: ['wsaa'] do
    subject { instancia.auth_hash }

    it { is_expected.to be_kind_of Hash }
  end

  describe '#wsaa', vcr_cassettes: ['wsaa'] do
    subject { instancia.wsaa.length }

    it { is_expected.to eq 2 }
  end

  pending 'error codes'
end
