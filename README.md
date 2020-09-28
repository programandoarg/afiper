[![CircleCI](https://circleci.com/gh/programandoarg/afiper.svg?style=shield)](https://circleci.com/gh/programandoarg/afiper)
[![Maintainability](https://api.codeclimate.com/v1/badges/9a7ddc4b5723beacde0d/maintainability)](https://codeclimate.com/github/programandoarg/afiper/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/9a7ddc4b5723beacde0d/test_coverage)](https://codeclimate.com/github/programandoarg/afiper/test_coverage)


# Afiper
Interfaz con los web services de la AFIP

## Testing

### Renovar cassetes

1. Borrar archivo spec/cassetes/wsaa.yml
2. Poner credenciales válidas de homologación en .env
3. Correr bundle exec rspec --tag wsaa
