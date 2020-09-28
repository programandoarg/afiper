require 'rails_helper'

describe Afiper::PadronClient do
  let(:cuit) { ENV['AFIP_CUIT'] }
  let(:afip_certificado) { ENV['AFIP_CERTIFICADO'] }
  let(:afip_clave_privada) { ENV['AFIP_CLAVE'] }
  let(:instancia) { described_class.new(cuit, afip_clave_privada, afip_certificado) }

  describe '#wsaa', :wsaa, vcr_cassettes: ['padron/wsaa'] do
    subject { instancia.wsaa.length }

    it { is_expected.to eq 2 }
  end

  describe '#get_persona', vcr_cassettes: ['padron/get_persona', 'padron/wsaa'] do
    subject { instancia.get_persona('20351404478') }

    it { is_expected.to be_a Hash }
  end
end
