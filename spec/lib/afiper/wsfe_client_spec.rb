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


  describe '#wsaa', :wsaa, vcr_cassettes: ['wsfe/wsaa'] do
    subject { instancia.wsaa.length }

    it { is_expected.to eq 2 }
  end

  describe '#auth_hash', vcr_cassettes: ['wsfe/wsaa'] do
    subject(:auth_hash) { instancia.auth_hash }

    it { is_expected.to be_a Hash }
    it { expect { auth_hash }.to change(Afiper::WsaaToken, :count).by 1 }

    context 'si ya hay un token en la db' do
      before do
        Afiper::WsaaToken.create(
          contribuyente: contribuyente,
          service: 'wsfe',
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

  describe '#call_auth', vcr_cassettes: ['wsfe/get_tipos_cbte', 'wsfe/wsaa'] do
    subject { instancia.call_auth(:fe_param_get_tipos_cbte) }
    
    it { is_expected.to be_a Hash }

    context 'cuando no se puede conectar al servidor',
      vcr_cassettes: ['wsfe/getaddrinfo', 'wsfe/wsaa'] do
      before do
        allow_any_instance_of(Afiper::WsfeClient).to \
          receive(:service_url).and_return('https://dominiofalso.gov.ar')
      end

      it { expect { subject }.to raise_error /Por favor intente nuevamente más tarde/i }
    end

    context 'cuando el servidor tira timeout', vcr_cassettes: ['wsfe/wsaa'] do
      before do
        allow_any_instance_of(Savon::Client).to receive(:call).and_raise(HTTPI::TimeoutError)
      end
      it { expect { subject }.to raise_error /Por favor intente nuevamente más tarde/i }
    end
  end

  describe '#autorizar_comprobante' do
    subject(:autorizar_comprobante) { instancia.autorizar_comprobante(comprobante) }

    context 'cuando autoriza correctamente', vcr_cassettes: ['wsfe/autorizar', 'wsfe/wsaa']  do
      it { is_expected.to be_truthy }
    end

    context 'cuando hace falta el CUIT', vcr_cassettes: ['wsfe/falta_cuit', 'wsfe/wsaa'] do
      let(:numero) { 3 }
      let(:receptor_doc_tipo) { 2 } # CUIL
      
      it { expect { autorizar_comprobante }.to raise_error having_attributes(error_code: "10013") }
      it { expect { autorizar_comprobante }.to raise_error /se debe ingresar un CUIT/i }
    end

    context 'cuando el cuit no es válido', vcr_cassettes: ['wsfe/cuit_invalido', 'wsfe/wsaa'] do
      let(:numero) { 3 }
      let(:receptor_doc_nro) { '1' }
      
      it { expect { autorizar_comprobante }.to raise_error having_attributes(error_code: "10015") }
      it { expect { autorizar_comprobante }.to raise_error /El documento .* no es válido/i }
    end

    context 'cuando hace falta fecha de servicio',
            vcr_cassettes: ['wsfe/falta_fecha_servicio', 'wsfe/wsaa'] do
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
    
    context 'cuando no es el próximo a autorizar',
      vcr_cassettes: ['wsfe/autorizar_fail', 'wsfe/wsaa'] do
      let(:numero) { 656 }
      
      it { expect { autorizar_o_actualizar }.to raise_error having_attributes(error_code: "10016") }
      it { expect { autorizar_o_actualizar }.to raise_error /no es el próximo a autorizar/i }
    end

    context 'cuando ya fue autorizado', vcr_cassettes: ['wsfe/ya_autorizado', 'wsfe/wsaa'] do
      let(:numero) { 1 }
      
      it { is_expected.to be_truthy }
      it { autorizar_o_actualizar; expect(comprobante).to be_autorizado }
    end
  end

  describe '#get_tipos_cbte', vcr_cassettes: ['wsfe/get_tipos_cbte', 'wsfe/wsaa'] do
    subject { instancia.get_tipos_cbte.length }
    
    it { is_expected.to eq 36 }
  end

  describe '#ultimo_cmp', vcr_cassettes: ['wsfe/ultimo_cmp', 'wsfe/wsaa'] do
    subject { instancia.ultimo_cmp(:factura_a, 1) }
    
    it { is_expected.to eq 0 }
  end
end
