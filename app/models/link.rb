class Link < Sequel::Model
    @@character_set = "0123456789abcdefghijklmnopqrstuvwxyz".split("")
    @@attempts_max = 8

    def self.prepend_protocol(url)
        return url if url.match(/^https?:\/\//)
        "http://#{url}"
    end

    def self.new_url?(url)
        Link.find(url: prepend_protocol(url)).nil?
    end

    def self.find(options)
        options[:short_url].downcase! if options[:short_url]
        Link[options]
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
            break unless Link.find(short_url: short_url) # must not reuse short_urls
        end
    end
end
