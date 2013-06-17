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
      it 'merges counters by calculating min, max, sum and avg of the count' do
        c1 = registry.counter(:c1)
        c2 = registry.counter(:c2)
        c3 = registry.counter(:c3)
        c1.inc(1)
        c2.inc(2)
        c3.inc(3)
        a = Aggregate.new('i1' => c1, 'i2' => c2, 'i3' => c3)
        a.to_h.should == {
          :type => :aggregate,
          :total => {:type => :counter, :count => { :min => 1.0, :max => 3.0, :sum => 6.0, :avg => 2.0 }},
          :parts => {
            'i1' => {:type => :counter, :count => 1},
            'i2' => {:type => :counter, :count => 2},
            'i3' => {:type => :counter, :count => 3}
          }
        }
      end

      it 'merges meters by picking the first event type, calculating min, max, sum and avg of the other properties' do
        m1 = stub(:meter1, :type => :meter, :to_h => {:type => :meter, :event_type => 'some_event', :count => 1, :mean_rate => 0.3, :one_minute_rate => 0.1, :five_minute_rate => 0.01, :fifteen_minute_rate => 0.9})
        m2 = stub(:meter2, :type => :meter, :to_h => {:type => :meter, :event_type => 'some_event', :count => 2, :mean_rate => 0.2, :one_minute_rate => 0.2, :five_minute_rate => 0.04, :fifteen_minute_rate => 0.2})
        m3 = stub(:meter3, :type => :meter, :to_h => {:type => :meter, :event_type => 'some_event', :count => 4, :mean_rate => 0.4, :one_minute_rate => 0.5, :five_minute_rate => 0.03, :fifteen_minute_rate => 0.4})
        a = Aggregate.new('i1' => m1, 'i2' => m2, 'i3' => m3)
        a.to_h.should == {
          :type => :aggregate,
          :total => {
            :type => :meter,
            :event_type => 'some_event',
            :count => {
                :min => 1,
                :max => 4,
                :sum => 1 + 2 + 4,
                :avg => 7/3.0
              },
            :mean_rate => {
                :min => 0.2,
                :max => 0.4,
                :sum => 0.3 + 0.2 + 0.4,
                :avg => 0.9/3
              },
            :one_minute_rate => {
                :min => 0.1,
                :max => 0.5,
                :sum => 0.1 + 0.2 + 0.5,
                :avg => 0.8/3,
              },
            :five_minute_rate => {
                :min => 0.01,
                :max => 0.04,
                :sum => 0.01 + 0.04 + 0.03,
                :avg => 0.08/3
              },
            :fifteen_minute_rate => {
                :min => 0.2,
                :max => 0.9,
                :sum => 0.9 + 0.2 + 0.4,
                :avg => 1.5/3
              }
          },
          :parts => {
            'i1' => m1.to_h,
            'i2' => m2.to_h,
            'i3' => m3.to_h
          }
        }
      end

      it 'merges histograms by picking the first type, calculating min, max, sum and avg of the other properties' do
        h1 = stub(:histogram1, :type => :histogram, :to_h => {:type => :histogram, :count => 1, :mean => 0.5, :max => 3, :min => 3, :std_dev => 0.5, :sum =>  9})
        h2 = stub(:histogram2, :type => :histogram, :to_h => {:type => :histogram, :count => 2, :mean => 0.4, :max => 4, :min => 0, :std_dev => 0.4, :sum => 11})
        h3 = stub(:histogram3, :type => :histogram, :to_h => {:type => :histogram, :count => 4, :mean => 0.3, :max => 5, :min => 1, :std_dev => 0.9, :sum => 10})
        a = Aggregate.new('i1' => h1, 'i2' => h2, 'i3' => h3)
        a.to_h.should == {
          :type => :aggregate,
          :total => {
            :type => :histogram,
            :count => {
              :min => 1,
              :max => 4,
              :sum => 1 + 2 + 4,
              :avg => 7/3.0
            },
            :mean => {
              :min => 0.3,
              :max => 0.5,
              :sum => 0.5 + 0.4 + 0.3,
              :avg => 1.2/3
            },
            :max => {
              :min => 3,
              :max => 5,
              :sum => 3 + 4 + 5,
              :avg => 12/3.0
            },
            :min => {
              :min => 0,
              :max => 3,
              :sum => 3 + 0 + 1,
              :avg => 4/3.0
            },
            :std_dev => {
              :min => 0.4,
              :max => 0.9,
              :sum => 0.5 + 0.4 + 0.9,
              :avg => 1.8/3
            },
            :sum => {
              :min => 9,
              :max => 11,
              :sum => 9 + 11 + 10,
              :avg => 30/3.0
            }
          },
          :parts => {
            'i1' => h1.to_h,
            'i2' => h2.to_h,
            'i3' => h3.to_h
          }
        }
      end

      it 'merges gauges by calculating min, max, sum and avg of the value' do
        g1 = registry.gauge(:g1) { 3 }
        g2 = registry.gauge(:g2) { 6 }
        g3 = registry.gauge(:g3) { 9 }
        a = Aggregate.new('i1' => g1, 'i2' => g2, 'i3' => g3)
        a.to_h.should == {
          :type => :aggregate,
          :total => {:type => :gauge, :value => {
              :min => 3,
              :max => 9,
              :sum => 3 + 6 + 9,
              :avg => 18/3.0
            }
          },
          :parts => {
            'i1' => {:type => :gauge, :value => 3},
            'i2' => {:type => :gauge, :value => 6},
            'i3' => {:type => :gauge, :value => 9}
          }
        }
      end

      it 'merges timers by picking the first type and event type, calculating min, max, sum and avg of the other properties and discards percentiles' do
        t1 = stub(:timer1, :type => :timer, :to_h => {:type => :timer, :event_type => 'some_event', :count => 1, :mean_rate => 0.3, :one_minute_rate => 0.1, :five_minute_rate => 0.01, :fifteen_minute_rate => 0.9, :mean => 0.5, :max => 3, :min => 3, :std_dev => 0.5, :sum =>  9, :percentiles => {'75' => 75.0, '95' => 95.0, '98' => 98.0, '99' => 99.0, '99.9' => 99.9}})
        t2 = stub(:timer2, :type => :timer, :to_h => {:type => :timer, :event_type => 'some_event', :count => 2, :mean_rate => 0.2, :one_minute_rate => 0.2, :five_minute_rate => 0.04, :fifteen_minute_rate => 0.2, :mean => 0.4, :max => 4, :min => 0, :std_dev => 0.4, :sum => 11, :percentiles => {'75' => 75.0, '95' => 95.0, '98' => 98.0, '99' => 99.0, '99.9' => 99.9}})
        t3 = stub(:timer3, :type => :timer, :to_h => {:type => :timer, :event_type => 'some_event', :count => 4, :mean_rate => 0.4, :one_minute_rate => 0.5, :five_minute_rate => 0.03, :fifteen_minute_rate => 0.4, :mean => 0.3, :max => 5, :min => 1, :std_dev => 0.9, :sum => 10}, :percentiles => {'75' => 75.0, '95' => 95.0, '98' => 98.0, '99' => 99.0, '99.9' => 99.9})
        a = Aggregate.new('i1' => t1, 'i2' => t2, 'i3' => t3)
        a.to_h.should == {
          :type => :aggregate,
          :total => {
            :type => :timer,
            :event_type => 'some_event',
            :count => {
              :min => 1,
              :max => 4,
              :sum => 1 + 2 + 4,
              :avg => 7/3.0
            },
            :mean_rate => {
              :min => 0.2,
              :max => 0.4,
              :sum => 0.3 + 0.2 + 0.4,
              :avg => 0.9/3.0
            },
            :one_minute_rate => {
              :min => 0.1,
              :max => 0.5,
              :sum => 0.1 + 0.2 + 0.5,
              :avg => 0.8/3.0
            },
            :five_minute_rate => {
              :min => 0.01,
              :max => 0.04,
              :sum => 0.01 + 0.04 + 0.03,
              :avg => 0.08/3.0
            },
            :fifteen_minute_rate => {
              :min => 0.2,
              :max => 0.9,
              :sum => 0.9 + 0.2 + 0.4,
              :avg => 1.5/3.0
            },
            :mean => {
              :min => 0.3,
              :max => 0.5,
              :sum => 0.5 + 0.4 + 0.3,
              :avg => 1.2/3.0
            },
            :max => {
              :min => 3,
              :max => 5,
              :sum => 3 + 4 + 5,
              :avg => 12/3.0
            },
            :min => {
              :min => 0,
              :max => 3,
              :sum => 1 + 0 + 3,
              :avg => 4/3.0
            },
            :std_dev => {
              :min => 0.4,
              :max => 0.9,
              :sum => 0.5 + 0.4 + 0.9,
              :avg => 1.8/3.0
            },
            :sum => {
              :min => 9,
              :max => 11,
              :sum => 9 + 11 + 10,
              :avg => 30/3.0
            }
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

      it 'handles the case when some values are nil' do
        t1 = stub(:counter, :type => :counter, :to_h => {:type => :counter, :count => 1})
        t2 = stub(:counter, :type => :counter, :to_h => {:type => :counter, :count => nil})
        t3 = stub(:counter, :type => :counter, :to_h => {:type => :counter, :count => 3})
        a = Aggregate.new('i1' => t1, 'i2' => t2, 'i3' => t3)
        p a.to_h[:total][:count].should == {:max => 3, :min => 1, :sum => 4, :avg => 4/3.0}
      end

      it 'handles the case when all values are nil' do
        t1 = stub(:counter, :type => :counter, :to_h => {:type => :counter, :count => nil})
        t2 = stub(:counter, :type => :counter, :to_h => {:type => :counter, :count => nil})
        t3 = stub(:counter, :type => :counter, :to_h => {:type => :counter, :count => nil})
        a = Aggregate.new('i1' => t1, 'i2' => t2, 'i3' => t3)
        p a.to_h[:total][:count].should == {:max => nil, :min => nil, :sum => nil, :avg => nil}
      end
    end
  end
end