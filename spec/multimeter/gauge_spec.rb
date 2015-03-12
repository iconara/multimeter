# encoding: utf-8

require 'spec_helper'

module Multimeter
  describe Gauge do
    let :gauge do
      MetricRegistry.new.gauge('a_gauge') { @value }
    end

    before do
      @value = 3
    end

    describe '#value' do
      it 'calls the block and returns its value' do
        expect(gauge.value).to eq(3)
        @value = 5
        expect(gauge.value).to eq(5)
      end
    end

    describe '#to_h' do
      it 'returns a hash representation of the gauge' do
        expect(gauge.to_h).to eq(
          :type => :gauge,
          :value => 3
        )
      end
    end
  end
end
