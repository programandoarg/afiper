# frozen_string_literal: true
require 'afiper/application_controller'

module Afiper
  class ContribuyentesController < ApplicationController
    before_action :set_contribuyente, only: %i[show edit update destroy]

    def index
      @contribuyentes = Contribuyente.order(:id)
    end

    def new
      @contribuyente = Contribuyente.new
    end

    def create
      @contribuyente = Contribuyente.new(contribuyente_params)
      respond_to do |format|
        if @contribuyente.save
          format.html { redirect_to contribuyentes_path, notice: 'contribuyente was successfully created.' }
          format.json { render action: 'show', status: :created, location: @contribuyente }
        else
          format.html { render action: 'new' }
          format.json { render json: @contribuyente.errors, status: :unprocessable_entity }
        end
      end
    end

    def update
      respond_to do |format|
        @contribuyente.puntos_de_venta = params.require(:puntos_de_venta)
        @contribuyente.save
        if @contribuyente.update(contribuyente_params)
          format.html { redirect_to contribuyentes_path, notice: 'contribuyente was successfully updated.' }
          format.json { head :no_content }
        else
          format.html { render action: 'edit' }
          format.json { render json: @contribuyente.errors, status: :unprocessable_entity }
        end
      end
    end

    def destroy
      @contribuyente.destroy
      respond_to do |format|
        format.html { go_back }
        format.json { head :no_content }
      end
    end

    def edit; end

    def show; end

    private

      def set_contribuyente
        @contribuyente = Contribuyente.find(params[:id])
      end

      def contribuyente_params
        params.require(:contribuyente).permit(:razon_social, :cuit, :iibb, :inicio_actividades, :condicion_iva, :domicilio, :service_wsfe, :service_padron, :afip_certificado, :afip_clave, :afip_certificado_homologacion, :afip_clave_homologacion)
      end
  end
end
