#\ -p 80

require 'dashing'

configure do
  set :default_dashboard, 'dashboard'
  set :environment, :production
end

map Sinatra::Application.assets_prefix do
  run Sinatra::Application.sprockets
end

run Sinatra::Application