# encoding: utf-8

require 'spec_helper'

module Multimeter
  describe Metrics do
    let :registry do
      Multimeter.create_registry
    end

    describe Metrics::Counter do
      describe '#to_h' do
        it 'returns a hash representation of the counter' do
          c = registry.counter(:a_counter)
          c.inc
          c.to_h.should == {:type => :counter, :count => 1}
        end
      end
    end

    describe Metrics::Meter do
      describe '#to_h' do
        it 'returns a hash representation of the meter' do
          m = registry.meter(:some_meter)
          m.mark
          h = m.to_h
          h[:type].should == :meter
          h[:count].should == 1
          h[:mean_rate].should be_a(Numeric)
          h[:one_minute_rate].should be_a(Numeric)
          h[:five_minute_rate].should be_a(Numeric)
          h[:fifteen_minute_rate].should be_a(Numeric)
        end
      end
    end

    describe Metrics::Histogram do
      it 'returns a hash representation of the histogram' do
        hs = registry.histogram(:some_hist)
        hs.update(4)
        h = hs.to_h
        h[:type].should == :histogram
        h[:count].should == 1
        h[:max].should be_a(Numeric)
        h[:min].should be_a(Numeric)
        h[:mean].should be_a(Numeric)
        h[:std_dev].should be_a(Numeric)
        h[:median].should be_a(Numeric)
        h[:percentiles]['75'].should be_a(Numeric)
        h[:percentiles]['95'].should be_a(Numeric)
        h[:percentiles]['98'].should be_a(Numeric)
        h[:percentiles]['99'].should be_a(Numeric)
        h[:percentiles]['99.9'].should be_a(Numeric)
      end
    end

    describe Metrics::Timer do
      describe '#measure' do
        it 'returns the value of the block' do
          t = registry.timer(:timer)
          t.measure { 42 }.should == 42
        end
      end

      describe '#to_h' do
        it 'returns a hash representation of the timer' do
          t = registry.timer(:some_timer)
          t.measure { }
          h = t.to_h
          h[:type].should == :timer
          h[:count].should == 1
          h[:mean_rate].should be_a(Numeric)
          h[:one_minute_rate].should be_a(Numeric)
          h[:five_minute_rate].should be_a(Numeric)
          h[:fifteen_minute_rate].should be_a(Numeric)
          h[:max].should be_a(Numeric)
          h[:min].should be_a(Numeric)
          h[:mean].should be_a(Numeric)
          h[:std_dev].should be_a(Numeric)
          h[:median].should be_a(Numeric)
          h[:percentiles]['75'].should be_a(Numeric)
          h[:percentiles]['95'].should be_a(Numeric)
          h[:percentiles]['98'].should be_a(Numeric)
          h[:percentiles]['99'].should be_a(Numeric)
          h[:percentiles]['99.9'].should be_a(Numeric)
        end
      end
    end

    describe Metrics::Gauge do
      describe '#to_h' do
        it 'returns a hash representation of the gauge' do
          g = registry.gauge(:some_gauge) { 42 }
          g.to_h.should == {:type => :gauge, :value => 42}
        end

      end
    end

    describe Metrics::MetricRegistry do
      %w[counter meter histogram timer].each do |type|
        describe "##{type}" do
          it 'raises an argument exception if another metric has this name already' do
            registry.gauge(:occupied) { 32 }
            expect do
              registry.send(type, :occupied)
            end.to raise_error(ArgumentError, /occupied/)
          end

          it 'returns the original metric if registered with the same type' do
            first = registry.send(type, :occupied)
            second = registry.send(type, :occupied)
            second.should equal(first)
          end
        end
      end

      describe '#gauge' do
        it 'raises an argument exception if already existing with different type' do
          registry.counter(:occupied)
          expect do
            registry.gauge(:occupied) { 42 }
          end.to raise_error(ArgumentError, /occupied/)
        end

        it 'raises an argument exception if already existing with same type' do
          registry.gauge(:some_gauge) { 42 }
          expect do
            registry.gauge(:some_gauge) { 42 }
          end.to raise_error(ArgumentError, /some_gauge/)
        end
      end

      describe '#to_h' do
        it 'returns a hash representing all the metrics' do
          registry.counter(:a_counter)
          registry.gauge(:some_gauge) { 42 }
          registry.meter(:some_meter)
          registry.histogram(:some_hist)
          registry.timer(:timer)
          registry.to_h.keys.map(&:to_s).sort.should == %w[a_counter some_gauge some_hist some_meter timer]
          registry.to_h.each_value do |value|
            value.should be_a(Hash)
            value.should_not be_empty
          end
        end
      end
    end
  end
end