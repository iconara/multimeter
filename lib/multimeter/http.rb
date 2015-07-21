# encoding: utf-8

require 'multimeter'
require 'metrics-servlets-jars'
require 'rjack-jetty'

module Metrics
  module Servlets
    include_package 'com.codahale.metrics.servlets'
  end
end

module Jetty
  include_package 'org.eclipse.jetty.server'
  include_package 'org.eclipse.jetty.servlet'
end

module Multimeter
  module Http
    def http(registry, options={})
      server = Jetty::Server.new(options[:port] || 5747)
      server.handler = create_servlet_context(registry)
      Server.new(server)
    end

    private

    def create_servlet_context(registry)
      context = Jetty::ServletContextHandler.new(Jetty::ServletContextHandler::SESSIONS)
      context.context_path = '/'
      context.set_attribute(Metrics::Servlets::MetricsServlet::METRICS_REGISTRY, registry.to_java)
      context.add_servlet(Metrics::Servlets::MetricsServlet.java_class, '/*')
      context
    end

    class Server
      def initialize(server)
        @server = server
      end

      def start
        @server.start
        self
      end

      def stop
        @server.stop
        self
      end

      def join
        @server.join
      end
    end
  end

  extend Http
end
