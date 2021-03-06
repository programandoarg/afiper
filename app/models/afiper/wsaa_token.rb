# frozen_string_literal: true

# == Schema Information
#
# Table name: afiper_wsaa_tokens
#
#  id                      :bigint           not null, primary key
#  afiper_contribuyente_id :bigint           not null
#  token                   :string           not null
#  sign                    :string           not null
#  cuit                    :string           not null
#  service                 :string           not null
#  homologacion            :boolean          not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#

require 'afiper/application_record'

module Afiper
  # Token para pegarle a la API de la AFIP
  class WsaaToken < ApplicationRecord
    def auth_hash_wsfe
      { Token: token, Sign: sign, Cuit: cuit }
    end

    def auth_hash_padron
      { token: token, sign: sign, cuitRepresentada: cuit }
    end
  end
end
