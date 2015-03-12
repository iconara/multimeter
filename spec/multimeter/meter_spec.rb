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

    describe '#to_h' do
      it 'returns a hash representation of the meter' do
        meter.mark
        h = meter.to_h
        expect(h[:type]).to eq(:meter)
        expect(h[:count]).to eq(1)
        expect(h[:mean_rate]).to be_a(Numeric)
        expect(h[:one_minute_rate]).to be_a(Numeric)
        expect(h[:five_minute_rate]).to be_a(Numeric)
        expect(h[:fifteen_minute_rate]).to be_a(Numeric)
      end
    end
  end
end
