Afiper::Engine.routes.draw do
  resources :contribuyentes
  get "/health", to: "health#health"
end
