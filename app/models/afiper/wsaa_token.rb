# frozen_string_literal: true

module Afiper
  class WsaaToken < ActiveRecord::Base
    belongs_to :contribuyente, class_name: 'Afiper::Contribuyente', foreign_key: :afiper_contribuyente_id

    def auth_hash
      { Token: token, Sign: sign, Cuit: cuit }
    end
  end
end
