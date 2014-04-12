require 'sequel'

# Connect to database
if defined?(UrlShortener)
    DB = Sequel.connect(UrlShortener::DB_URL)
else

    # Enables DB access from ruby console without loading entire app.
    # use 'require_relative app/models/init'
    DB = Sequel.connect(ENV['HEROKU_POSTGRESQL_RED_URL'] || ENV['DATABASE_URL'] || "sqlite://debug.db")
end


# Load models
require_relative 'link'
