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
    belongs_to :contribuyente, class_name: 'Afiper::Contribuyente',
                               foreign_key: :afiper_contribuyente_id

    def auth_hash
      { Token: token, Sign: sign, Cuit: cuit }
    end
  end
end
