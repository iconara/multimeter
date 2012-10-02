require_relative '../spec_helper'


module Multimeter
  module DslSpecs
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

    class ClassWithLinkedMetrics1
      include LinkedMetrics

      counter :stuff

      def do_stuff
        stuff.inc
      end
    end

    class ClassWithLinkedMetrics2
      include LinkedMetrics

      counter :stuff

      def do_stuff
        stuff.inc
      end
    end

    class ClassWithLinkedInstanceMetrics
      include LinkedInstanceMetrics

      counter :stuff

      def do_stuff
        stuff.inc
      end
    end
  
    class ClassWithCustomGroup
      include Metrics

      group :a_very_special_group
      counter :stuff
    end

    class ClassWithCustomScope
      include Metrics

      scope :a_scope_unlinke_other_scopes
      counter :stuff
    end
  
    class ClassWithGauge
      include Metrics

      gauge :current_value do
        @a_value
      end

      def self.set_a_value=(v)
        @a_value = v
      end
    end

    class ClassWithInstanceGauge
      include InstanceMetrics

      gauge :current_value do
        @a_value
      end

      def set_a_value=(v)
        @a_value = v
      end
    end
  end

  describe 'DSL' do
    describe Metrics do
      it 'scopes metrics to the class' do
        i1 = DslSpecs::ClassWithMetrics.new
        i2 = DslSpecs::ClassWithMetrics.new
        i1.do_stuff
        i1.do_stuff
        i2.do_stuff
        i1.stuff.count.should == 3
        i2.stuff.count.should == 3
      end
    end

    describe InstanceMetrics do
      it 'scopes metrics to each instance' do
        i1 = DslSpecs::ClassWithInstanceMetrics.new
        i2 = DslSpecs::ClassWithInstanceMetrics.new
        i1.do_stuff
        i1.do_stuff
        i2.do_stuff
        i1.stuff.count.should == 2
        i2.stuff.count.should == 1
      end
    end

    describe GlobalMetrics do
      it 'scopes metrics to each instance' do
        i1 = DslSpecs::ClassWithGlobalMetrics1.new
        i2 = DslSpecs::ClassWithGlobalMetrics2.new
        i1.do_stuff
        i1.do_stuff
        i2.do_stuff
        i1.stuff.count.should == 3
        i2.stuff.count.should == 3
        Multimeter.global_registry.get(:stuff).count.should == 3
      end
    end

    describe LinkedMetrics do
      it 'scopes metrics to the class, but registers the registry in a global hierarchy' do
        i1 = DslSpecs::ClassWithLinkedMetrics1.new
        i2 = DslSpecs::ClassWithLinkedMetrics2.new
        i1.do_stuff
        i1.do_stuff
        i2.do_stuff
        Multimeter.global_registry.sub_registry('ClassWithLinkedMetrics1').get(:stuff).count.should == 2
        Multimeter.global_registry.sub_registry('ClassWithLinkedMetrics2').get(:stuff).count.should == 1
      end
    end

    describe LinkedInstanceMetrics do
      it 'scopes metrics to the instance, but registers the registry in a global hierarchy' do
        i1 = DslSpecs::ClassWithLinkedInstanceMetrics.new
        i2 = DslSpecs::ClassWithLinkedInstanceMetrics.new
        i1.do_stuff
        i1.do_stuff
        i2.do_stuff
        all_registries = Multimeter.global_registry.sub_registries
        instance_registries = all_registries.select { |r| r.scope.start_with?('ClassWithLinkedInstanceMetrics') }
        instance_registries.map { |x| x.get(:stuff).count }.sort.should == [1,2]
      end
    end
  
    context 'with defaults' do
      it 'has a group derived from the parent module\'s name' do
        DslSpecs::ClassWithMetrics.new.multimeter_registry.group.should == 'Multimeter::DslSpecs'
      end

      it 'has a scope derived from the class name' do
        DslSpecs::ClassWithMetrics.new.multimeter_registry.scope.should == 'ClassWithMetrics'
      end
    end

    context 'with customizations' do
      it 'allows the group to be overridden' do
        DslSpecs::ClassWithCustomGroup.new.multimeter_registry.group.should == 'a_very_special_group'
      end

      it 'allows the scope to be overridden' do
        DslSpecs::ClassWithCustomScope.new.multimeter_registry.scope.should == 'a_scope_unlinke_other_scopes'
      end
    end
  
    context 'with gauges' do
      it 'runs the gauge in class context when the metrics are class scoped' do
        DslSpecs::ClassWithGauge.set_a_value = 42
        i1 = DslSpecs::ClassWithGauge.new
        i2 = DslSpecs::ClassWithGauge.new
        i1.current_value.value.should == 42
        i2.current_value.value.should == 42
      end

      it 'runs the gauge in instance context when the metrics are instance scoped' do
        i1 = DslSpecs::ClassWithInstanceGauge.new
        i2 = DslSpecs::ClassWithInstanceGauge.new
        i1.set_a_value = 42
        i2.set_a_value = 43
        i1.current_value.value.should == 42
        i2.current_value.value.should == 43
      end
    end
  end
end
