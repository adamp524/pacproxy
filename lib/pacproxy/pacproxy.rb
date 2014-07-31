require 'pacproxy'
require 'webrick/httpproxy'
require 'uri'

module Pacproxy
  # Pacproxy::Pacproxy represent http/https proxy server
  class Pacproxy < WEBrick::HTTPProxyServer
    include Loggable

    def initialize(config = {}, default = WEBrick::Config::HTTP)
      config[:Logger] = general_logger
      super(config, default)
      @pac = PacFile.new(config[:Proxypac])
    end

    def proxy_uri(req, res)
      super(req, res)
      return unless @pac

      proxy_line = @pac.find(request_uri(req))
      lookup_proxy_uri(proxy_line)
    end

    def request_uri(request)
      if 'CONNECT' == request.request_method
        "https://#{request.header['host'][0]}/"
      else
        request.unparsed_uri
      end
    end

    def lookup_proxy_uri(proxy_line)
      case proxy_line
      when /^DIRECT/
        nil
      when /PROXY/
        primary_proxy = proxy_line.split(';')[0]
        proxy = /PROXY (.*)/.match(primary_proxy)[1]
        URI.parse("http://#{proxy}")
      end
    end
  end
end
