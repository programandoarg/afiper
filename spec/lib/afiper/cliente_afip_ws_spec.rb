require 'rails_helper'

describe Afiper::ClienteAfipWs do
  let(:contribuyente) do
    create :afiper_contribuyente,
      cuit: ENV['AFIP_CUIT'],
      afip_certificado: ENV['AFIP_CERTIFICADO'],
      afip_clave: ENV['AFIP_CLAVE'],
      afip_certificado_homologacion: ENV['AFIP_CERTIFICADO'],
      afip_clave_homologacion: ENV['AFIP_CLAVE']
  end
  let(:service_name) { 'wsfe' }
  let(:service_url) { 'https://wswhomo.afip.gov.ar/wsfev1/service.asmx?WSDL' }
  let(:instancia) do
    described_class.new(
      contribuyente: contribuyente,
      service_name: service_name,
      service_url: service_url,
    )
  end

  describe '#wsaa', :wsaa, vcr_cassettes: ['wsaa'] do
    subject { instancia.wsaa.length }

    it { is_expected.to eq 2 }

    context 'wsfex', :wsaa, vcr_cassettes: ['wsaa_wsfex'] do
      let(:service_name) { 'wsfex' }

      it { is_expected.to eq 2 }
    end
  end

  describe '#auth_hash', vcr_cassettes: ['wsaa'] do
    subject(:auth_hash) { instancia.auth_hash }

    it { is_expected.to be_a Hash }
    it { expect { auth_hash }.to change(Afiper::WsaaToken, :count).by 1 }

    context 'si ya hay un token en la db' do
      before do
        Afiper::WsaaToken.create(
          contribuyente: contribuyente,
          service: service_name,
          homologacion: true,
          cuit: '',
          sign: '',
          token: ''
        )
      end
      it { expect { auth_hash }.not_to change(Afiper::WsaaToken, :count) }
    end
  end

  describe '#generar_tra' do
    subject { instancia.generar_tra }

    it { is_expected.to be_a String }
  end

  describe '#call_auth', vcr_cassettes: ['get_tipos_cbte', 'wsaa'] do
    subject { instancia.call_auth(:fe_param_get_tipos_cbte) }
    
    it { is_expected.to be_a Hash }

    context 'cuando no se puede conectar al servidor', vcr_cassettes: ['getaddrinfo', 'wsaa'] do
      let(:service_url) { 'https://dominiofalso.gov.ar/wsfev1/service.asmx?WSDL' }

      it { expect { subject }.to raise_error /Por favor intente nuevamente más tarde/i }
    end

    context 'cuando el servidor tira timeout', vcr_cassettes: ['wsaa'] do
      before do
        allow_any_instance_of(Savon::Client).to receive(:call).and_raise(HTTPI::TimeoutError)
      end
      it { expect { subject }.to raise_error /Por favor intente nuevamente más tarde/i }
    end
  end
end
