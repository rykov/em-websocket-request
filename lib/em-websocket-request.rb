require 'em-http-request'
require "em-ws-request/version"
require "em-ws-request/client"
require "em-ws-request/wrapper"

module EventMachine
  class WebsocketRequest < HttpRequest
    def self.new(uri, options={})
      connopt = HttpConnectionOptions.new(uri, options)
      c = WebsocketConnection.new
      c.connopts = connopt
      c.uri = uri
      c
    end
  end
end