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

  # describe '#get_puntos_venta', vcr_cassettes: ['get_puntos_venta', 'wsaa']  do
  #   subject { instancia.get_puntos_venta.length }
    
  #   it { is_expected.to eq [] }
  # end

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
end
