require_relative '../spec_helper'


module Multimeter
  describe Registry do
    let :registry do
      Multimeter.registry('a_group', 'some_type')
    end

    context 'when creating metrics' do
      [:counter, :meter, :histogram, :timer].each do |metric_type|
        it "##{metric_type} creates a new #{metric_type}" do
          metric = registry.send(metric_type, :some_name)
          metric.should_not be_nil
        end
      end

      it '#gauge creates a gauge' do
        registry.gauge(:some_name) { 42 }
      end

      it 'caches metric objects' do
        registry.counter(:some_name).should equal(registry.counter(:some_name))
      end

      it 'raises an error when a gauge is redeclared, but not when it is accessed without a block' do
        g1 = registry.gauge(:some_name) { 42 }
        g2 = registry.gauge(:some_name)
        g1.should equal(g2)
        expect { registry.gauge(:some_name) { 43 } }.to raise_error(ArgumentError)
      end

      it 'raises an error if a metric is redeclared as another type' do
        registry.counter(:some_name)
        expect { registry.meter(:some_name) }.to raise_error(ArgumentError)
      end
    end

    describe '#to_h' do
      it 'returns a hash representation of the registry, including all metrics' do
        m = registry.meter(:some_meter)
        c = registry.counter(:some_counter)
        g = registry.gauge(:some_gauge) { 42 }
        m.mark
        c.inc
        h = registry.to_h
        h[:group].should == 'a_group'
        h[:type].should == 'some_type'
        h[:metrics].should have_key(:some_meter)
        h[:metrics].should have_key(:some_counter)
        h[:metrics].should have_key(:some_gauge)
      end
    end
  end
end