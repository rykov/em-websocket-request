module EventMachine
  class WebsocketConnection < HttpConnection
    def setup_request(method, options = {}, c = nil)
      c ||= WebsocketClient.new(self, HttpClientOptions.new(@uri, options, method))
      @deferred ? activate_connection(c) : finalize_request(c)
      c
    end

    def post_init
      super
      @p.on_message_complete = proc do
        if not client.continue?
          if client.state == :websocket
            client.state = :stream
          else
            client.state = :finished
            client.on_request_complete
          end
        end
      end
    end

    def receive_data(data)
      if client.state == :stream
        client.receive(data)
      else
        super(data)
      end
    end
  end

  class WebsocketClient < HttpClient
    PROTOCOL_VERSION = '8'

    def initialize(conn, options)
      super(conn, options)
      @wswrapper = WebSocketWrapper.new(self, PROTOCOL_VERSION)
    end

    def send(data, frame_type = :text)
      @connection = @conn
      if state == :stream || state == :websocket # FIXME
        @wswrapper.send_frame(frame_type, data)
      end
    end

    def send_data(data)
      @conn.send_data(data)
    end

    def receive(data)
      out = @wswrapper.receive(data)
      @stream.call(out) if @stream
    end

    def websocket?
      @req.uri.scheme == 'ws' || @req.uri.scheme == 'wss'
    end

    def build_request
      head = super
      if websocket?
        @sec_websocket_key = @wswrapper.generate_key
        head.delete_if { |k, v| !%w(host).include?(k) }
        head['upgrade'] = 'websocket'
        head['connection'] = 'Upgrade'
        head['origin'] = @req.uri.host
        head['Sec-WebSocket-Key'] = @sec_websocket_key
        head['Sec-WebSocket-Version'] = PROTOCOL_VERSION
      end
      head
    end

    def parse_response_header(header, version, status)
      super
      if websocket?
        # p [:parse_response_header, :WEBSOCKET]
        if @response_header.status != 101

          fail "websocket handshake failed (not status 101)"
        elsif @wswrapper.security_digest(@sec_websocket_key) !=
              @response_header['SEC_WEBSOCKET_ACCEPT']

          fail "websocket handshake failed (mismatched key)"
        else
          @state = :websocket
          succeed
        end
      end
    end

    #### DISCONNECT ####
    def disconnect(&blk)
      @disconnect = blk
    end

    def unbind(reason = nil)
      if state == :stream || state == :websocket # FIXME
        @disconnect.call(self) if @disconnect
        on_error(reason) # TODO: Should we really barf on unbind?
      else
        super(reason)
      end
    end
  end
end

