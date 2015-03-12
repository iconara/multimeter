# encoding: utf-8

require 'spec_helper'

module Multimeter
  describe Histogram do
    let :histogram do
      MetricRegistry.new.histogram('an_histogram')
    end

    describe '#update/#count' do
      it 'keeps track of the number of updates' do
        histogram.update(3)
        histogram.update(1)
        histogram.update(2)
        expect(histogram.count).to eq(3)
      end
    end

    describe '#snapshot' do
      let :snapshot do
        histogram.snapshot
      end

      before do
        histogram.update(3)
        histogram.update(1)
        histogram.update(2)
      end

      it 'knows the number of samples' do
        expect(snapshot.size).to eq(3)
      end

      it 'knows the maximum value' do
        expect(snapshot.max).to eq(3)
      end

      it 'knows the minimum value' do
        expect(snapshot.min).to eq(1)
      end

      it 'knows the mean' do
        expect(snapshot.mean).to eq(2.0)
      end

      it 'knows the median' do
        expect(snapshot.median).to eq(2.0)
      end

      it 'knows the standard deviation' do
        expect(snapshot.std_dev).to be_a(Numeric)
      end

      it 'has convenience accessors for common percentiles' do
        expect(snapshot.p75).to eq(3.0)
        expect(snapshot.p95).to eq(3.0)
        expect(snapshot.p98).to eq(3.0)
        expect(snapshot.p99).to eq(3.0)
        expect(snapshot.p999).to eq(3.0)
      end

      it 'can return a specific percentile' do
        expect(snapshot.value(0.50)).to eq(2.0)
      end

      it 'can return all the samples' do
        expect(snapshot.values).to eq([1, 2, 3])
      end
    end

    it 'returns a hash representation of the histogram' do
      histogram.update(4)
      h = histogram.to_h
      expect(h[:type]).to eq(:histogram)
      expect(h[:count]).to eq(1)
      expect(h[:max]).to be_a(Numeric)
      expect(h[:min]).to be_a(Numeric)
      expect(h[:mean]).to be_a(Numeric)
      expect(h[:std_dev]).to be_a(Numeric)
      expect(h[:median]).to be_a(Numeric)
      expect(h[:percentiles]['75']).to be_a(Numeric)
      expect(h[:percentiles]['95']).to be_a(Numeric)
      expect(h[:percentiles]['98']).to be_a(Numeric)
      expect(h[:percentiles]['99']).to be_a(Numeric)
      expect(h[:percentiles]['99.9']).to be_a(Numeric)
    end
  end
end
