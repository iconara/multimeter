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
      object_name = Java::JavaxManagement::ObjectName.new(domain, 'name', metric_name)
      Java::JavaLangManagement::ManagementFactory.getPlatformMBeanServer.getAttribute(object_name, attribute)
    end

    it 'publishes metrics using JMX' do
      registry.counter('a_counter')
      registry.meter('a_meter')
      registry.timer('a_timer')
      registry.histogram('an_histogram')
      registry.gauge('a_gauge') { 3 }
      expect(get_attribute('a_counter', 'Count')).to eq(0)
      expect(get_attribute('a_meter', 'Count')).to eq(0)
      expect(get_attribute('a_timer', 'Count')).to eq(0)
      expect(get_attribute('an_histogram', 'Count')).to eq(0)
      expect(get_attribute('a_gauge', 'Value')).to eq(3)
    end
  end
end
