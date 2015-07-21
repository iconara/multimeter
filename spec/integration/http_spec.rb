# encoding: utf-8

require 'spec_helper'
require 'open-uri'
require 'support/json_metrics'

module Multimeter
  describe Http do
    let :registry do
      MetricRegistry.new
    end

    let :port do
      loop do
        port = rand(1024...2**15)
        begin
          TCPSocket.new('localhost', port).close
        rescue Errno::ECONNREFUSED
          return port
        end
      end
    end

    let :server do
      Multimeter.http(registry, port: port)
    end

    before do
      server.start
    end

    after do
      server.stop
      server.join
    end

    describe 'GET /' do
      let :json do
        open("http://localhost:#{port}").read
      end

      include_examples 'json-metrics'
    end
  end
end