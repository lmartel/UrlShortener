# Initialize Sequel models
require_relative 'models/init'

# Load Sinatra controller/view helpers
require_relative 'helpers/helpers'
UrlShortener.helpers UrlShortenerHelpers

# Load app routes
require_relative 'routes/routes'
