require_relative '../spec_helper'


module Yammer::Metrics
  describe Yammer::Metrics do
    let :registry do
      Multimeter.registry('a_group', 'some_type')
    end

    describe Counter do
      describe '#to_h' do
        it 'returns a hash representation of the counter' do
          c = registry.counter(:a_counter)
          c.inc
          c.to_h.should == {:type => :counter, :count => 1}
        end
      end
    end

    describe Meter do
      describe '#to_h' do
        it 'returns a hash representation of the meter' do
          m = registry.meter(:some_meter, :event_type => 'stuff')
          m.mark
          h = m.to_h
          h[:type].should == :meter
          h[:event_type].should == 'stuff'
          h[:count].should == 1
          h[:mean_rate].should be_a(Numeric)
          h[:one_minute_rate].should be_a(Numeric)
          h[:five_minute_rate].should be_a(Numeric)
          h[:fifteen_minute_rate].should be_a(Numeric)
        end
      end
    end

    describe Histogram do
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
        h[:sum].should be_a(Numeric)
      end
    end

    describe Timer do
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
          h[:event_type].should == 'calls'
          h[:count].should == 1
          h[:mean_rate].should be_a(Numeric)
          h[:one_minute_rate].should be_a(Numeric)
          h[:five_minute_rate].should be_a(Numeric)
          h[:fifteen_minute_rate].should be_a(Numeric)
          h[:max].should be_a(Numeric)
          h[:min].should be_a(Numeric)
          h[:mean].should be_a(Numeric)
          h[:std_dev].should be_a(Numeric)
          h[:sum].should be_a(Numeric)
        end
      end
    end

    describe Gauge do
      describe '#to_h' do
        it 'returns a hash representation of the gauge' do
          g = registry.gauge(:some_gauge) { 42 }
          g.to_h.should == {:type => :gauge, :value => 42}
        end
      end
    end
  end
end