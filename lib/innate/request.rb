module Innate

  # Subclass Rack::Request and add some convenient methods.
  #
  # An instance is available via the #request method in your Node.
  #
  # NOTE:
  #   Please make sure to read the documentation of Rack::Request together with
  #   this, as there are a lot of features available.
  #
  # A list of methods from Rack::Request so you get a gist of it:
  #
  # ## Generally
  #
  # * body
  # * cookies
  # * env
  # * fullpath
  # * host
  # * port
  # * scheme
  # * url
  #
  # ## ENV shortcuts
  #
  # * accept_encoding
  # * content_charset
  # * content_length
  # * content_type
  # * ip
  # * media_type
  # * media_type_params
  # * path_info
  # * path_info=
  # * query_string
  # * referrer
  # * script_name
  # * script_name=
  # * xhr?
  #
  # ## Query request method
  #
  # * delete?
  # * get?
  # * head?
  # * post?
  # * put?
  # * request_method
  #
  # ## parameter handling
  #
  # * []
  # * []=
  # * form_data?
  # * params
  # * values_at

  class Request < Rack::Request
    # Currently handled request from Innate::STATE[:request]
    # Call it from anywhere via Innate::Request.current
    def self.current
      Current.request
    end

    # Let's allow #[] to act like #values_at.
    #
    # Usage given a GET request like /hey?foo=duh&bar=doh
    #
    #   request[:foo, :bar] # => ['duh', 'doh']
    #
    # Both +value+ and the elements of +keys+ will be turned into String by #to_s.
    def [](value, *keys)
      return super(value) if keys.empty?
      [value, *keys].map{|k| super(k) }
    end

    def request_uri
      env['REQUEST_URI'] || env['PATH_INFO']
    end

    # Answers with a subset of request.params with only the key/value pairs for
    # which you pass the keys.
    # Valid keys are objects that respond to :to_s
    #
    # Example:
    #   request.params
    #   # => {'name' => 'jason', 'age' => '45', 'job' => 'lumberjack'}
    #   request.subset('name')
    #   # => {'name' => 'jason'}
    #   request.subset(:name, :job)
    #   # => {'name' => 'jason', 'job' => 'lumberjack'}

    def subset(*keys)
      keys = keys.map{|k| k.to_s }
      params.reject{|k,v| not keys.include?(k) }
    end

    # Try to figure out the domain we are running on, this might work for some
    # deployments but fail for others, given the combination of servers in
    # front.

    def domain(path = '/')
      scheme = env['rack.url_scheme'] || 'http'
      host = env['HTTP_HOST']
      URI("#{scheme}://#{host}#{path}")
    end

    # Try to find out which languages the client would like to have.
    # Returns and array of locales from env['HTTP_ACCEPT_LANGUAGE].
    # e.g. ["fi", "en", "ja", "fr", "de", "es", "it", "nl", "sv"]

    def accept_language
      env['HTTP_ACCEPT_LANGUAGE'].to_s.split(/(?:,|;q=[\d.,]+)/)
    end
    alias locales accept_language

    ipv4 = %w[ 127.0.0.1/32 192.168.0.0/16 172.16.0.0/12 10.0.0.0/8 169.254.0.0/16 ]
    ipv6 = %w[ fc00::/7 fe80::/10 fec0::/10 ::1 ]
    LOCAL = (ipv4 + ipv6).map{|a| IPAddr.new(a)} unless defined?(LOCAL)

    # Request is from a local network?
    # Checks both IPv4 and IPv6
    # Answer is true if the IP address making the request is from local network.
    # Optional argument address can be used to check any IP address.

    def local_net?(address = ip)
      addr = IPAddr.new(address)
      LOCAL.find{|range| range.include?(addr) }
    rescue ArgumentError => ex
      raise ArgumentError, ex unless ex.message == 'invalid address'
    end
  end
end
