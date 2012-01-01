module EventMachine
  class WsClientOptions < HttpClientOptions
    def ssl?; @uri.scheme == "wss" || super; end
  end
end