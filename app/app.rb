require 'rubygems'
require 'sinatra/base'
require 'sinatra/assetpack'
require 'rack/csrf'
require 'sequel'
require 'less'

# App configuration: AssetPack, database, CSRF setup.
# Also checks that environment variables are properly set up.
class UrlShortener < Sinatra::Base
    set :root, File.dirname(__FILE__) # assetpack requires explicitly set root
    register Sinatra::AssetPack
    assets do
        css_dir = 'assets/css'
        serve '/css',    from: css_dir
        # serve '/js',     from: 'assets/js'
        # serve '/images', from: 'assets/images'

        Less.paths << File.join(UrlShortener.root, css_dir)

        css_compression :less
        css :application, '/css/application.css', [
          '/css/app.css'
        ]

        # js_compression  :jsmin
        # js :app, '/js/app.js', [
        #   '/js/app.js'
        # ]
    end

    # Make sure ENV is set up properly
    def self.check_env(vars)
        vars = [vars] unless vars.kind_of?(Array)
        vars.each do |var|
            unless ENV[var]
                err = "Missing environment variable: #{var}" 
                puts err
                raise err
            end
        end
    end

    configure :production do
      Bundler.require :production
      
      check_env 'HEROKU_POSTGRESQL_RED_URL'
      DB_URL = ENV['HEROKU_POSTGRESQL_RED_URL']
      HOST = "http://"
      ROOT = "lpm.io/"
    end

    configure :development do
      Bundler.require :development

      check_env 'DATABASE_URL'
      DB_URL = ENV['DATABASE_URL']
      HOST = "."
      ROOT = "/"
    end

    # Global setup, incl. CSRF protection
    configure do
        check_env [ 'LINK_LENGTH', 'SECRET_TOKEN', 'ADMIN_PASSWORD' ]

        use Rack::Session::Cookie, secret: ENV['SECRET_TOKEN']
        use Rack::Protection, except: :http_origin
        Sequel.extension :migration
    end  
end

require_relative 'init'
