require "em-ws-request/vendor/web-socket-ruby/lib/web_socket"

module EventMachine
  class WebSocketWrapper < ::WebSocket
    def initialize(client, version)
      @handshaked = true
      @client = client
      @web_socket_version = version
    end

    def send_frame(opcode, data, mask = true)
      opcode = type_to_opcode(opcode) if opcode.is_a?(Symbol)
      super(opcode, data, mask)
    end

    def write(data)
      @client.send_data(data)
    end

    def receive(data)
      @incoming_data = data
      super()
    end

    def read(num_bytes)
      str = @incoming_data.slice(0, num_bytes)
      @incoming_data = @incoming_data[num_bytes..-1]
      return str
    end

    # Called on a CLOSE frame
    def close(code = 1005, reason = "", origin = :self)
      origin = :self if origin == :peer # to skip @socket.close
      super(code, reason, origin)
      @client.unbind
    end

    # Used for Sec-WebSocket-Key and Sec-WebSocket-Accept auth
    public :security_digest, :generate_key

  private
    FRAME_TYPES = {
      :continuation => 0,
      :text => 1,
      :binary => 2,
      :close => 8,
      :ping => 9,
      :pong => 10,
    }

    def type_to_opcode(frame_type)
      FRAME_TYPES[frame_type] || raise("Unknown frame type")
    end
  end
end

