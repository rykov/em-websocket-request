require 'em-websocket'
require 'em-websocket-request'

describe EventMachine::WebsocketRequest do

  context "websocket connection" do
    # Spec: http://tools.ietf.org/html/draft-hixie-thewebsocketprotocol-55
    #
    # ws.onopen     = http.callback
    # ws.onmessage  = http.stream { |msg| }
    # ws.errback    = no connection
    #

    it "should invoke errback on failed upgrade" do
      EventMachine.run {
        http = websocket_test_request(:timeout => 0)

        http.callback { failed(http) }
        http.errback {
          http.response_header.status.should == 0
          EventMachine.stop
        }
      }
    end

    it "should complete websocket handshake and transfer data from client to server and back" do
      EventMachine.run {
        MSG = "hello bi-directional data exchange"

        with_websocket_test_server do |ws|
          ws.onopen { p [:OPENED_WS, ws]}
          ws.onmessage {|msg| ws.send msg}
          ws.onerror {|e| p [:WS_ERROR, e]}
          ws.onclose { p [:WS_CLOSE, ws]}
        end

        http = websocket_test_request
        http.errback { failed(http) }
        http.callback {
          http.response_header.status.should == 101
          http.response_header['CONNECTION'].should match(/Upgrade/)
          http.response_header['UPGRADE'].should match(/websocket/)

          # push should only be invoked after handshake is complete
          http.send(MSG)
        }

        http.stream { |chunk|
          chunk.should == MSG
          EventMachine.stop
        }
      }
    end

    # parser eats up the trailign data
    # [:receive, "HTTP/1.1 101 Web Socket Protocol Handshake\r\nUpgrade: WebSocket\r\nConnection: Upgrade\r\nWebSocket-Origin: 127.0.0.1\r\nWebSocket-Location: ws://127.0.0.1:8085/\r\n\r\n\x001\xFF\x002\xFF", :keep_alive?, "#<HTTP::Parser:0x0000010132d000>"]

    it "should split multiple messages from websocket server into separate stream callbacks" do
      EM.run do
        messages = %w[1 2]
        recieved = []

        with_websocket_test_server do |ws|
          ws.onopen do
            EventMachine.add_timer(0.1) { ws.send messages[0] }
            EventMachine.add_timer(0.2) { ws.send messages[1] }
          end
        end

        http = websocket_test_request
        http.errback { failed(http) }
        http.callback { http.response_header.status.should == 101; p 'WS CONNECTED' }
        http.stream {|msg|
          p ['GOT MSG ', msg]
          msg.should == messages[recieved.size]
          recieved.push msg
          p [:MULTI_MESAGE, recieved]
          EventMachine.stop if recieved.size == messages.size
        }
      end
    end

    it "should process close on message correctly " do
      EM.run {
        MSG = "hello bi-directional data exchange"

        with_websocket_test_server do |ws|
          ws.onopen { p [:OPENED_WS, ws] }
          ws.onmessage { |msg| ws.close_websocket }
          ws.onerror {|e| p [:WS_ERROR, e] }
          ws.onclose { p [:WS_CLOSE, ws] }
        end

        http = websocket_test_request
        http.errback  { failed(http) }
        http.callback { http.send(MSG) }
        http.disconnect { EventMachine.stop }
        http.stream { |chunk|
          # FIXME We should not receive a chunk!
          chunk.should be_nil
        }
      }
    end
  end

  def with_websocket_test_server(&block)
    opts = { :host => "0.0.0.0", :port => 8085, :debug => true }
    EventMachine::WebSocket.start(opts, &block)
  end

  def websocket_test_request(opts = {})
    req = EventMachine::WebsocketRequest.new('ws://127.0.0.1:8085/')
    req.get(opts.merge(:keepalive => true))
  end
end