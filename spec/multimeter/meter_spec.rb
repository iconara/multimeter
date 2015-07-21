# encoding: utf-8

require 'spec_helper'

module Multimeter
  describe Meter do
    let :meter do
      MetricRegistry.new.meter('a_meter')
    end

    describe '#mark/#count' do
      it 'counts the number or times it has been marked' do
        meter.mark
        expect(meter.count).to be(1)
      end

      it 'can be marked a specific number of times' do
        meter.mark(3)
        expect(meter.count).to be(3)
      end
    end

    describe '#*_rate' do
      it 'knows the mean rate' do
        meter.mark
        expect(meter.mean_rate).to be_a(Float)
      end

      it 'knows the one minute rate' do
        meter.mark
        expect(meter.one_minute_rate).to be_a(Float)
      end

      it 'knows the five minute rate' do
        meter.mark
        expect(meter.five_minute_rate).to be_a(Float)
      end

      it 'knows the fifteen minute rate' do
        meter.mark
        expect(meter.fifteen_minute_rate).to be_a(Float)
      end
    end

    describe '#to_json' do
      it 'returns a json representation of the meter' do
        meter.mark
        expect(JSON.parse(meter.to_json)).to include(
          'count' => 1,
          'mean_rate' => be_a(Numeric),
          'm1_rate' => be_a(Numeric),
          'm5_rate' => be_a(Numeric),
          'm15_rate' => be_a(Numeric),
        )
      end
    end
  end
end
