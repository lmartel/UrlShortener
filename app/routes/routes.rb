class UrlShortener < Sinatra::Base
    get '/:param?' do |url|
        if url == "links"
            protected!
            partial :links
        elsif url

            # /short_url! => view stats page for this link
            if url[-1] == '!' 
                render_link_page Link.find(short_url: url[0..-2])
            elsif link = Link.find(short_url: url)
                link.visits += 1
                link.save

                # 301 Moved Permanently [to avoid messing up target site's Google Analytics etc]
                redirect link.url, 301
            else
                # 302 Moved Temporarily [this shorturl is not currently in use, but may be eventually]
                redirect 'http://lpm.io/404', 302
            end
        else
            partial :index
        end
    end

    get '/links/:short_url' do |short_url|
        render_link_page Link.find(short_url: short_url)
    end

    post '/links' do
        url = Link.prepend_protocol(params[:url])
        if url && Link.new_url?(url)
            short_url = Link.create(url: url).short_url
        elsif url
            short_url = Link.find(url: url).short_url
        else
            short_url = ""
        end
        redirect "/#{short_url}!"
    end
end
