module Afiper
  class WsaaToken < ActiveRecord::Base
    belongs_to :contribuyente

    def auth_hash
      { Token: token, Sign: sign, Cuit: cuit }
    end
  end
end
