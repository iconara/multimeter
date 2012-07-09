require_relative '../spec_helper'


module Multimeter
  module Specs
    class ClassWithMetrics
      include Metrics

      counter :stuff

      def do_stuff
        stuff.inc
      end
    end

    class ClassWithInstanceMetrics
      include InstanceMetrics

      counter :stuff

      def do_stuff
        stuff.inc
      end
    end

    class ClassWithGlobalMetrics1
      include GlobalMetrics

      counter :stuff

      def do_stuff
        stuff.inc
      end
    end

    class ClassWithGlobalMetrics2
      include GlobalMetrics

      counter :stuff

      def do_stuff
        stuff.inc
      end
    end
  end

  describe 'DSL' do
    describe Metrics do
      it 'scopes metrics to the class' do
        i1 = Specs::ClassWithMetrics.new
        i2 = Specs::ClassWithMetrics.new
        i1.do_stuff
        i1.do_stuff
        i2.do_stuff
        i1.stuff.count.should == 3
        i2.stuff.count.should == 3
      end
    end

    describe InstanceMetrics do
      it 'scopes metrics to each instance' do
        i1 = Specs::ClassWithInstanceMetrics.new
        i2 = Specs::ClassWithInstanceMetrics.new
        i1.do_stuff
        i1.do_stuff
        i2.do_stuff
        i1.stuff.count.should == 2
        i2.stuff.count.should == 1
      end
    end

    describe GlobalMetrics do
      it 'scopes metrics to each instance' do
        i1 = Specs::ClassWithGlobalMetrics1.new
        i2 = Specs::ClassWithGlobalMetrics2.new
        i1.do_stuff
        i1.do_stuff
        i2.do_stuff
        i1.stuff.count.should == 3
        i2.stuff.count.should == 3
      end
    end
  end
end
