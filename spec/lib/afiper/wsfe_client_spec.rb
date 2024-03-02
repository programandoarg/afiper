require 'rails_helper'

describe Afiper::WsfeClient do
  let(:cuit) { ENV['AFIP_CUIT'] }
  let(:afip_certificado) { ENV['AFIP_CERTIFICADO'] }
  let(:afip_clave_privada) { ENV['AFIP_CLAVE'] }
  let(:instancia) { described_class.new(cuit, afip_clave_privada, afip_certificado) }

  let(:item) { build :afiper_item, cantidad: 1, importe: 300 }
  let(:pventa) { 2 }
  let(:numero) { 1 }
  let(:receptor_doc_tipo) { 1 } # CUIT
  let(:receptor_doc_nro) { '20120791827' }
  let(:tipo_factura) { :factura_a }
  let(:comprobante) do
    create :afiper_comprobante, tipo_comprobante: tipo_factura, items: [item], numero: numero,
                                receptor_doc_tipo: receptor_doc_tipo, punto_de_venta: pventa,
                                receptor_doc_nro: receptor_doc_nro, fecha: Date.today
  end


  describe '#wsaa', :wsaa, vcr_cassettes: ['wsfe/wsaa'] do
    subject { instancia.wsaa.length }

    it { is_expected.to eq 2 }
  end

  describe '#token', vcr_cassettes: ['wsfe/wsaa'] do
    subject(:token) { instancia.token }

    it { is_expected.to be_a Afiper::WsaaToken }
    it { expect { token }.to change(Afiper::WsaaToken, :count).by 1 }

    context 'si ya hay un token en la db' do
      before do
        Afiper::WsaaToken.create(
          cuit: cuit,
          service: 'wsfe',
          homologacion: true,
          sign: '',
          token: ''
        )
      end
      it { expect { token }.not_to change(Afiper::WsaaToken, :count) }
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

    context 'cuando el servidor tira error', vcr_cassettes: ['wsfe/wsaa'] do
      before do
        http_error = Savon::HTTPError.new(OpenStruct.new(code: 500, body: 'server error'))
        allow_any_instance_of(Savon::Client).to receive(:call).and_raise(http_error)
      end
      it { expect { subject }.to raise_error /Error interno en el servidor de la AFIP/i }
      it { expect { subject }.to raise_error /Por favor intente nuevamente más tarde/i }
    end
  end

  describe '#autorizar_comprobante' do
    subject(:autorizar_comprobante) { instancia.autorizar_comprobante(comprobante) }

    context 'cuando autoriza correctamente', vcr_cassettes: ['wsfe/autorizar', 'wsfe/wsaa']  do
      it { is_expected.to be_truthy }
    end

    context 'cuando autoriza correctamente tipo C', vcr_cassettes: ['wsfe/autorizar_c', 'wsfe/wsaa']  do
      let(:tipo_factura) { :factura_c }
      let(:pventa) { 2 }
      let(:numero) { 2 }
      let(:comprobante) do
        create :afiper_comprobante, tipo_comprobante: tipo_factura, items: [item], numero: numero,
                                    receptor_doc_tipo: receptor_doc_tipo, punto_de_venta: pventa,
                                    receptor_doc_nro: receptor_doc_nro, fecha: Date.today
      end

      it do
        is_expected.to be_truthy
      end

      context 'cuando autoriza correctamente tipo nota de credito C', vcr_cassettes: ['wsfe/autorizar_nc_c', 'wsfe/wsaa']  do
        let(:numero) { 1 }
        let(:tipo_factura) { :nota_de_credito_c }
        let(:item_asoc) { build :afiper_item, cantidad: 1, importe: 300 }
        let(:comprobante_asoc) do
          create :afiper_comprobante, tipo_comprobante: :factura_c, items: [item_asoc], numero: 1,
                                      receptor_doc_tipo: receptor_doc_tipo, punto_de_venta: pventa,
                                      receptor_doc_nro: receptor_doc_nro, fecha: Date.today
        end

        before do
          comprobante.update(comprobante_asociado: comprobante_asoc)
        end

        it do
          is_expected.to be_truthy
        end
      end
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
