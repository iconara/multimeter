require_relative '../spec_helper'


module Multimeter
  describe Aggregate do
    let(:registry) { Multimeter.registry('a_group', 'some_scope') }

    describe '#initialize' do
      it 'raises an error if no all metrics are of the same type' do
        c1 = registry.counter(:c1)
        c2 = registry.counter(:c2)
        m3 = registry.meter(:m3)
        expect { Aggregate.new('i1' => c1, 'i2' => c2, 'i3' => m3) }.to raise_error(ArgumentError)
      end
    end

    describe '#to_h' do
      it 'merges counters by summing the count' do
        c1 = registry.counter(:c1)
        c2 = registry.counter(:c2)
        c3 = registry.counter(:c3)
        c1.inc(1)
        c2.inc(2)
        c3.inc(3)
        a = Aggregate.new('i1' => c1, 'i2' => c2, 'i3' => c3)
        a.to_h.should == {
          :type => :aggregate,
          :total => {:type => :counter, :count => 6.0},
          :parts => {
            'i1' => {:type => :counter, :count => 1},
            'i2' => {:type => :counter, :count => 2},
            'i3' => {:type => :counter, :count => 3}
          }
        }
      end

      it 'merges meters by picking the first event type, summing the count and averaging the other properties' do
        m1 = stub(:meter1, :type => :meter, :to_h => {:type => :meter, :event_type => 'some_event', :count => 1, :mean_rate => 0.3, :one_minute_rate => 0.1, :five_minute_rate => 0.01, :fifteen_minute_rate => 0.9})
        m2 = stub(:meter2, :type => :meter, :to_h => {:type => :meter, :event_type => 'some_event', :count => 2, :mean_rate => 0.2, :one_minute_rate => 0.2, :five_minute_rate => 0.04, :fifteen_minute_rate => 0.2})
        m3 = stub(:meter3, :type => :meter, :to_h => {:type => :meter, :event_type => 'some_event', :count => 4, :mean_rate => 0.4, :one_minute_rate => 0.5, :five_minute_rate => 0.03, :fifteen_minute_rate => 0.4})
        a = Aggregate.new('i1' => m1, 'i2' => m2, 'i3' => m3)
        a.to_h.should == {
          :type => :aggregate,
          :total => {
            :type => :meter,
            :event_type => 'some_event',
            :count => 1 + 2 + 4,
            :mean_rate => (0.3 + 0.2 + 0.4)/3,
            :one_minute_rate => (0.1 + 0.2 + 0.5)/3,
            :five_minute_rate => (0.01 + 0.04 + 0.03)/3,
            :fifteen_minute_rate => (0.9 + 0.2 + 0.4)/3
          },
          :parts => {
            'i1' => m1.to_h,
            'i2' => m2.to_h,
            'i3' => m3.to_h
          }
        }
      end

      it 'merges histograms by summing the count and sum, picking the total max and min, and averaging the other properties' do
        h1 = stub(:histogram1, :type => :histogram, :to_h => {:type => :histogram, :count => 1, :mean => 0.5, :max => 3, :min => 3, :std_dev => 0.5, :sum =>  9})
        h2 = stub(:histogram2, :type => :histogram, :to_h => {:type => :histogram, :count => 2, :mean => 0.4, :max => 4, :min => 0, :std_dev => 0.4, :sum => 11})
        h3 = stub(:histogram3, :type => :histogram, :to_h => {:type => :histogram, :count => 4, :mean => 0.3, :max => 5, :min => 1, :std_dev => 0.9, :sum => 10})
        a = Aggregate.new('i1' => h1, 'i2' => h2, 'i3' => h3)
        a.to_h.should == {
          :type => :aggregate,
          :total => {
            :type => :histogram,
            :count => 1 + 2 + 4,
            :mean => (0.5 + 0.4 + 0.3)/3,
            :max => 5,
            :min => 0,
            :std_dev => (0.5 + 0.4 + 0.9)/3,
            :sum => 9 + 11 + 10
          },
          :parts => {
            'i1' => h1.to_h,
            'i2' => h2.to_h,
            'i3' => h3.to_h
          }
        }
      end

      it 'merges gauges by averaging the value' do
        g1 = registry.gauge(:g1) { 3 }
        g2 = registry.gauge(:g2) { 6 }
        g3 = registry.gauge(:g3) { 9 }
        a = Aggregate.new('i1' => g1, 'i2' => g2, 'i3' => g3)
        a.to_h.should == {
          :type => :aggregate,
          :total => {:type => :gauge, :value => (3 + 6 + 9)/3},
          :parts => {
            'i1' => {:type => :gauge, :value => 3},
            'i2' => {:type => :gauge, :value => 6},
            'i3' => {:type => :gauge, :value => 9}
          }
        }
      end

      it 'merges timers by summing the count and sum, picking the total max and min, and averaging the other properties' do
        t1 = stub(:timer1, :type => :timer, :to_h => {:type => :timer, :event_type => 'some_event', :count => 1, :mean_rate => 0.3, :one_minute_rate => 0.1, :five_minute_rate => 0.01, :fifteen_minute_rate => 0.9, :mean => 0.5, :max => 3, :min => 3, :std_dev => 0.5, :sum =>  9})
        t2 = stub(:timer2, :type => :timer, :to_h => {:type => :timer, :event_type => 'some_event', :count => 2, :mean_rate => 0.2, :one_minute_rate => 0.2, :five_minute_rate => 0.04, :fifteen_minute_rate => 0.2, :mean => 0.4, :max => 4, :min => 0, :std_dev => 0.4, :sum => 11})
        t3 = stub(:timer3, :type => :timer, :to_h => {:type => :timer, :event_type => 'some_event', :count => 4, :mean_rate => 0.4, :one_minute_rate => 0.5, :five_minute_rate => 0.03, :fifteen_minute_rate => 0.4, :mean => 0.3, :max => 5, :min => 1, :std_dev => 0.9, :sum => 10})
        a = Aggregate.new('i1' => t1, 'i2' => t2, 'i3' => t3)
        a.to_h.should == {
          :type => :aggregate,
          :total => {
            :type => :timer,
            :event_type => 'some_event',
            :count => 1 + 2 + 4,
            :mean_rate => (0.3 + 0.2 + 0.4)/3,
            :one_minute_rate => (0.1 + 0.2 + 0.5)/3,
            :five_minute_rate => (0.01 + 0.04 + 0.03)/3,
            :fifteen_minute_rate => (0.9 + 0.2 + 0.4)/3,
            :mean => (0.5 + 0.4 + 0.3)/3,
            :max => 5,
            :min => 0,
            :std_dev => (0.5 + 0.4 + 0.9)/3,
            :sum => 9 + 11 + 10
          },
          :parts => {
            'i1' => t1.to_h,
            'i2' => t2.to_h,
            'i3' => t3.to_h
          }
        }
      end

      it 'stringifies instance IDs' do
        c1 = registry.counter(:c1)
        c2 = registry.counter(:c2)
        a = Aggregate.new(1 => c1, 2 => c2)
        a.to_h[:parts].should have_key('1')
      end
    end
  end
end