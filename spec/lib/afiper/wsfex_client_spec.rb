require 'rails_helper'

describe Afiper::WsfexClient do
  let(:cuit) { ENV['AFIP_CUIT'] }
  let(:afip_certificado) { ENV['AFIP_CERTIFICADO'] }
  let(:afip_clave_privada) { ENV['AFIP_CLAVE'] }
  let(:instancia) { described_class.new(cuit, afip_clave_privada, afip_certificado) }

  let(:item) { build :afiper_item, cantidad: 1, importe: 300 }
  let(:pventa) { 1 }
  let(:numero) { 1 }
  let(:receptor_doc_tipo) { 1 } # CUIT
  let(:receptor_doc_nro) { '20120791827' }
  let(:receptor_domicilio) { Faker::Address.street_address }
  let(:receptor_cuit_pais) { Afiper::CuitPaises.opciones.keys.sample }
  let(:receptor_codigo_pais) { Afiper::Paises.opciones.keys.sample }
  let(:comprobante) do
    create :afiper_comprobante, tipo_comprobante: :factura_e, items: [item], numero: numero,
                                receptor_doc_tipo: receptor_doc_tipo, punto_de_venta: pventa,
                                receptor_doc_nro: receptor_doc_nro, fecha: Date.today,
                                receptor_domicilio: receptor_domicilio,
                                receptor_codigo_pais: receptor_codigo_pais,
                                receptor_cuit_pais: receptor_cuit_pais
  end

  describe '#wsaa', :wsaa, vcr_cassettes: ['wsfex/wsaa'] do
    subject { instancia.wsaa.length }

    it { is_expected.to eq 2 }
  end

  describe '#autorizar_comprobante' do
    subject(:autorizar_comprobante) { instancia.autorizar_comprobante(comprobante) }

    context 'cuando autoriza correctamente', vcr_cassettes: ['wsfex/autorizar', 'wsfex/wsaa']  do
      it { is_expected.to be_truthy }
      it { autorizar_comprobante; expect(comprobante).to be_autorizado }
    end

    context 'cuando hace falta el CUIT', vcr_cassettes: ['wsfex/falta_cuit', 'wsfex/wsaa'] do
      let(:numero) { 2 }
      let(:receptor_cuit_pais) { nil }
      
      it { expect { autorizar_comprobante }.to raise_error having_attributes(error_code: "1580") }
      it { expect { autorizar_comprobante }.to raise_error \
        /Debe informar el CUIT del pais destino/i }
    end

    context 'cuando hace falta el codigo pais',
      vcr_cassettes: ['wsfex/falta_codigo_pais', 'wsfex/wsaa'] do
      let(:numero) { 2 }
      let(:receptor_codigo_pais) { nil }
      
      it { expect { autorizar_comprobante }.to raise_error having_attributes(error_code: "1560") }
      it { expect { autorizar_comprobante }.to raise_error \
        /Debe informar el código del pais destino/i }
    end

    context 'cuando hace falta domicilio',
      vcr_cassettes: ['wsfex/falta_domicilio', 'wsfex/wsaa'] do
      let(:numero) { 2 }
      let(:receptor_domicilio) { nil }
      
      it { expect { autorizar_comprobante }.to raise_error having_attributes(error_code: "1661") }
      it { expect { autorizar_comprobante }.to raise_error \
        /Debe informar el domicilio del cliente/i }
    end
  end

  describe '#autorizar_comprobante' do
    subject(:autorizar_comprobante) { instancia.autorizar_comprobante(comprobante) }
    
    context 'cuando no es el próximo a autorizar',
      vcr_cassettes: ['wsfex/no_es_el_proximo', 'wsfex/wsaa'] do
      let(:numero) { 656 }
      
      it { expect { autorizar_comprobante }.to raise_error having_attributes(error_code: "1535") }
      it { expect { autorizar_comprobante }.to raise_error /no es el próximo a autorizar/i }
    end

    # context 'cuando ya fue autorizado', vcr_cassettes: ['wsfex_ya_autorizado', 'wsfex/wsaa'] do
    #   let(:numero) { 1 }
      
    #   it { is_expected.to be_truthy }
    #   it { autorizar_o_actualizar; expect(comprobante).to be_autorizado }
    # end
  end

  # En homologacion este metodo creo que no anda, siempre devuelve 0
  # describe '#ultimo_cmp', vcr_cassettes: ['wsfex_ultimo_cmp', 'wsfex/wsaa']  do
  #   subject(:ultimo_cmp) { instancia.ultimo_cmp(:factura_e, 1) }
  
  #   it { is_expected.to eq 1 }
  # end

  # fex_get_cmp no funciona en homologacion
  # describe '#actualizar_comprobante' do
  #   subject(:actualizar_comprobante) { instancia.actualizar_comprobante(comprobante) }
    
  #   context 'cuando ya fue autorizado', vcr_cassettes: ['wsfex_actualizar', 'wsfex/wsaa'] do
  #     let(:numero) { 1 }
      
  #     it { is_expected.to be_truthy }
  #     it { actualizar_comprobante; expect(comprobante).to be_autorizado }
  #   end
  # end
end
