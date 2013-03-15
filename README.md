# EventMachine Websocket Client

[![Gem Version](https://badge.fury.io/rb/em-websocket-request.png)](http://badge.fury.io/rb/em-websocket-request)

This gem implements a WebSocket client inside EventMachine building 
on top of `em-http-request` and [web-socket-ruby](https://github.com/gimite/web-socket-ruby).
Supports all the features of em-http-request including SSL, and 
timeout reconnect.

### Installation:

    gem install em-websocket-request

### Usage:

```ruby
require 'em-websocket-request'

request = EventMachine::WebsocketRequest.new(
  'wss://ws-1.fury.io',
  :inactivity_timeout => 30
).get

request.errback { |*args|
  puts "[websocket] problem connecting (will retry)"
  request.close
}

request.callback {
  puts "[websocket] Successfully connected"
}

request.disconnect {
  puts "[websocket] disconnected"
}

request.stream { |chunk, type|
  process_data(chunk, type)
}
```