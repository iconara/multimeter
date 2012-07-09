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
          c.to_h.should == {:count => 1}
        end
      end
    end

    describe Meter do
      describe '#to_h' do
        it 'returns a hash representation of the meter' do
          m = registry.meter(:some_meter, :event_type => 'stuff')
          m.mark
          h = m.to_h
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
        h[:count].should == 1
        h[:max].should be_a(Numeric)
        h[:min].should be_a(Numeric)
        h[:mean].should be_a(Numeric)
        h[:std_dev].should be_a(Numeric)
        h[:sum].should be_a(Numeric)
      end
    end

    describe Timer do
      describe '#to_h' do
        it 'returns a hash representation of the timer' do
          t = registry.timer(:some_timer)
          t.measure { }
          h = t.to_h
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
          g.to_h.should == {:value => 42}
        end
      end
    end
  end
end