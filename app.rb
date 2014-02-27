require 'rubygems'
require 'sinatra'
require 'rack/csrf'
require 'sequel'

require 'pg'
require 'newrelic_rpm'

# Make sure ENV is set up properly
def check_env(vars)
    vars = [vars] unless vars.kind_of?(Array)
    vars.each do |var|
        raise "Missing environment variable: #{var}" unless ENV[var]
    end
end

configure :production do
  check_env 'HEROKU_POSTGRESQL_RED_URL'

  DB = Sequel.connect(ENV['HEROKU_POSTGRESQL_RED_URL'])
  HOST = "http://"
  ROOT = "lpm.io/"
end

configure :development do
  check_env 'DATABASE_URL'

  DB = Sequel.connect(ENV['DATABASE_URL'])
  HOST = "."
  ROOT = "/"
end

# Global setup, incl. CSRF protection
configure do
    check_env [ 'LINK_LENGTH', 'SECRET_TOKEN' ]

    use Rack::Session::Cookie, secret: ENV['SECRET_TOKEN']
    use Rack::Protection, except: :http_origin
    Sequel.extension :migration
end

helpers do
    def csrf_token
        Rack::Csrf.csrf_token(env)
    end

    def csrf_tag
        Rack::Csrf.csrf_tag(env)
    end

    def render_link_page(link)
        @link = link
        erb :link
    end

    def path(dest)
        HOST + pretty_path(dest)
    end

    def pretty_path(dest)
        ROOT + dest
    end
end

# Connect to database

class Link < Sequel::Model
    @@character_set = "0123456789abcdefghijklmnopqrstuvwxyz".split("")
    @@attempts_max = 8

    def self.prepend_protocol(url)
        return url if url.match(/^https?:\/\//)
        "http://#{url}"
    end

    def self.new_url?(url)
        Link[url: prepend_protocol(url)].nil?
    end

    def before_create
        self.url = Link.prepend_protocol(url)
        shorten!
    end

    def shorten!(len = ENV['LINK_LENGTH'].to_i)
        attempts = 0
        loop do
            attempts += 1
            len += 1 if attempts > @@attempts_max 
            self.short_url = (1..len).map { @@character_set.sample }.join
            next unless self.short_url.match(/[a-z]/) # should include one letter (all numbers looks weird)
            next unless self.short_url.match(/[0-9]/) # should include one number (all letters looks not random enough)
            break unless Link[short_url: short_url] # must not reuse short_urls
        end
    end
end

get '/:param?' do |url|
    if url == "links"
        erb :links
    elsif url

        # /short_url! => view stats page for this link
        if url[-1] == '!' 
            render_link_page(Link[short_url: url[0..-2]])
        elsif link = Link[short_url: url]
            link.visits += 1
            link.save

            # 301 Moved Permanently [to avoid messing up target site's Google Analytics etc]
            redirect link.url, 301
        else
            # 302 Moved Temporarily [this shorturl is not currently in use, but may be eventually]
            redirect 'http://lpm.io/404', 302
        end
    else
        erb :index
    end
end

get '/links/:short_url' do |short_url|
    render_link_page(Link[short_url: short_url])
end

post '/links' do
    url = Link.prepend_protocol(params[:url])
    if url && Link.new_url?(url)
        short_url = Link.create(url: url).short_url
    elsif url
        short_url = Link[url: url].short_url
    else
        short_url = ""
    end
    redirect "/#{short_url}!"
end

# Link.create(url: "google.com") if Link.new_url?("google.com")
# Link.create(url: "yahoo.com") if Link.new_url?("yahoo.com")
# Link.each { |l| puts l.values; l.destroy }