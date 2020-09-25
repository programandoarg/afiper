Afiper.configure do |config|
  config.wsfe_homologacion = ENV['AFIP_ENV'] != 'produccion'
  config.padron_homologacion = ENV['AFIP_ENV'] != 'produccion'
end
