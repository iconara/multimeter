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

    describe '#to_json' do
      it 'returns a json representation of the histogram' do
        histogram.update(4)
        expect(JSON.parse(histogram.to_json)).to include(
          'count' => 1,
          'max' => 4.0,
          'min' => 4.0,
          'mean' => 4.0,
          'stddev' => 0.0,
          'p50' => 4.0,
          'p75' => 4.0,
          'p95' => 4.0,
          'p99' => 4.0,
          'p999' => 4.0,
        )
      end
    end
  end
end
