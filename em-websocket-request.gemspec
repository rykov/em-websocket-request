# -*- encoding: utf-8 -*-
require File.expand_path('../lib/em-ws-request/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Michael Rykov"]
  gem.email         = ["mrykov@gmail.com"]
  gem.description   = %q{EventMachine WebSocket client}
  gem.summary       = %q{EventMachine WebSocket client}
  gem.homepage      = ""

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "em-websocket-request"
  gem.require_paths = ["lib"]
  gem.version       = EventMachine::WS_REQUEST_VERSION

  gem.add_runtime_dependency 'em-http-request', '~> 1.0.0'
end
