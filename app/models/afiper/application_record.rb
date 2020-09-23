# frozen_string_literal: true

module Afiper
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
  end
end
