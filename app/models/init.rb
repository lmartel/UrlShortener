require 'sequel'

# Connect to database
DB = Sequel.connect(UrlShortener::DB_URL || "sqlite://debug.db")

# Load models
require_relative 'link'
