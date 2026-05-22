Rails.application.routes.draw do
  root "welcome#index"
  get "login", to: "logins#create", as: :create_login
end
