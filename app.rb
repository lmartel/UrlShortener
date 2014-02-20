require 'rubygems'
require 'sinatra'
require 'sequel'
require 'sqlite3'

[ 'DATABASE_URL', 'LINK_LENGTH' ].each do |var|
    raise "Missing environment variable: #{var}" unless ENV[var]
end

DB = Sequel.connect(ENV['DATABASE_URL'])
Sequel.extension :migration

# TODO:
# Analytics, track with either email auth or password

class Link < Sequel::Model
    @@character_set = "0123456789abcdefghijklmnopqrstuvwxyz".split("")
    @@attempts_max = 8

    def self.new_url?(url)
        Link[url: url].nil?
    end

    def before_create
        self.url = "http://#{self.url}" unless url.match(/^https?:\/\//)
        shorten!
    end

    def shorten!(len = ENV['LINK_LENGTH'].to_i)
        attempts = 0
        loop do
            attempts += 1
            len += 1 if attempts > @@attempts_max 
            self.short_url = (1..len).map { @@character_set.sample }.join
            break unless Link[short_url: short_url]
        end
    end
end

get '/:param?' do |url|
    if url == "links"
        erb :links
    elsif url
        link = Link[short_url: url]
        if link
            redirect link.url
        else
            erb :notfound
        end
    else
        erb :index
    end
end

get '/links/:short_url' do |short_url|
    @link = Link[short_url: short_url]
    erb :link
end

post '/links' do
    url = params[:url]
    if url && Link.new_url?(url)
        @link = Link.create(url: url)
    elsif url
        @link = Link[url: url]
    end
    erb :link
end



# Link.create(url: "google.com") if Link.new_url?("google.com")
# Link.create(url: "yahoo.com") if Link.new_url?("yahoo.com")
# Link.each { |l| puts l.values; l.destroy }