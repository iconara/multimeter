# encoding: utf-8

require 'spec_helper'

module Multimeter
  describe 'Multimeter.jmx' do
    let :registry do
      Multimeter.create_registry
    end

    let! :jmx do
      Multimeter.jmx(registry, domain: domain)
    end

    let :domain do
      'my-domain'.freeze
    end

    after do
      jmx.stop
    end

    def get_attribute(metric_name, attribute)
      Java::JavaLangManagement::ManagementFactory.getPlatformMBeanServer.getAttribute(Java::JavaxManagement::ObjectName.new(domain, 'name', metric_name), attribute)
    end

    it 'publishes metrics using jmx' do
      registry.counter(:a_counter)
      registry.gauge(:some_gauge) { 42 }
      registry.meter(:some_meter)
      registry.histogram(:some_hist)
      registry.timer(:timer)

      get_attribute('a_counter', 'Count').should == 0
      get_attribute('some_gauge', 'Value').should == 42
      get_attribute('some_meter', 'Count').should == 0
      get_attribute('some_hist', 'Count').should == 0
      get_attribute('timer', 'Count').should == 0
    end
  end
end
