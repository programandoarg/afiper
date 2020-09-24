# frozen_string_literal: true

module Afiper
  # Modelo base
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
  end
end
