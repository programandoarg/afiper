[![CircleCI](https://circleci.com/gh/programandoarg/afiper.svg?style=shield)](https://circleci.com/gh/programandoarg/afiper)
[![Maintainability](https://api.codeclimate.com/v1/badges/9a7ddc4b5723beacde0d/maintainability)](https://codeclimate.com/github/programandoarg/afiper/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/9a7ddc4b5723beacde0d/test_coverage)](https://codeclimate.com/github/programandoarg/afiper/test_coverage)


# Afiper
Interfaz con los web services de la AFIP

## Instalación

Agregar al Gemfile:

```ruby
gem 'afiper', git: 'https://github.com/programandoarg/afiper.git'
```

Y ejecutar:
```bash
$ bundle
```

Instalar las migraciones:
```bash
$ bundle exec rake afiper:install:migrations
$ bundle exec rake db:migrate
```

Montar las rutas:
```ruby
# routes.rb
Myapp::Application.routes.draw do
  mount Afiper::Engine => '/afiper'
end
```
## Uso

#### Linkear a la ruta de contribuyentes

```ruby
link_to "Contribuyentes", afiper.contribuyentes_path
```

## Testing

### Renovar cassetes

1. Borrar archivo spec/cassetes/wsaa.yml
2. Poner credenciales válidas de homologación en .env
3. Correr bundle exec rspec --tag wsaa

