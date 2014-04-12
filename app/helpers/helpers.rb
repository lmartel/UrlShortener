module UrlShortenerHelpers
    def csrf_token
        Rack::Csrf.csrf_token(env)
    end

    def csrf_tag
        Rack::Csrf.csrf_tag(env)
    end

    def protected!
        return if authorized?
        headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
        halt 401, "Not authorized\n"
    end

    def authorized?
        @auth ||=  Rack::Auth::Basic::Request.new(request.env)
        @auth.provided? and @auth.basic? and @auth.credentials and @auth.credentials == ['admin', ENV['ADMIN_PASSWORD']]
    end

    def partial(template)
        @template = template;
        erb :application
    end

    def render_link_page(link)
        @link = link
        partial :link
    end

    def error_message(code)
        case code
        when :invalid
            "invalid url; try again?"
        else
            puts "UNKNOWN ERROR CODE: #{code}"
            "an unknown error ocurred."
        end
    end

    def path(dest)
        UrlShortener::HOST + pretty_path(dest)
    end

    def pretty_path(dest)
        UrlShortener::ROOT + dest
    end

    def snip_protocol(url)
        url.gsub(/https?:\/\//, "")
    end
end