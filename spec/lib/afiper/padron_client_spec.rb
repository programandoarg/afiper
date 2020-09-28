require 'rails_helper'

describe Afiper::PadronClient do
  let(:contribuyente) do
    create :afiper_contribuyente,
      cuit: ENV['AFIP_CUIT'],
      afip_certificado: ENV['AFIP_CERTIFICADO'],
      afip_clave: ENV['AFIP_CLAVE'],
      afip_certificado_homologacion: ENV['AFIP_CERTIFICADO'],
      afip_clave_homologacion: ENV['AFIP_CLAVE']
  end
  let(:instancia) { described_class.new(contribuyente) }

  describe '#wsaa', :wsaa, vcr_cassettes: ['padron/wsaa'] do
    subject { instancia.wsaa.length }

    it { is_expected.to eq 2 }
  end

  describe '#get_persona', vcr_cassettes: ['padron/get_persona', 'padron/wsaa'] do
    subject { instancia.get_persona('20351404478') }

    it { is_expected.to be_a Hash }
  end
end
