# encoding: utf-8

require 'spec_helper'

module Multimeter
  describe Timer do
    let :timer do
      MetricRegistry.new.timer('a_timer')
    end

    describe '#update/#count' do
      it 'counts the number or times it has been marked' do
        timer.update(3, :seconds)
        expect(timer.count).to be(1)
      end

      it 'supports many different units' do
        timer.update(1, :days)
        timer.update(1, :hours)
        timer.update(1, :microseconds)
        timer.update(1, :milliseconds)
        timer.update(1, :minutes)
        timer.update(1, :nanoseconds)
        timer.update(1, :seconds)
      end

      context 'when no unit is given' do
        it 'assumes that the unit is seconds' do
          timer.update(1)
          expect(timer.snapshot.median).to eq(1_000_000_000)
        end

        it 'keeps fractions of seconds' do
          timer.update(1.3)
          expect(timer.snapshot.median).to eq(1_300_000_000)
        end
      end

      it 'raises an error when the unit is not supported' do
        expect { timer.update(1, :fnords) }.to raise_error(ArgumentError, /"fnords" not supported/i)
      end
    end

    describe '#time' do
      it 'returns a timer that can be stopped' do
        t = timer.time
        t.stop
        expect(timer.count).to eq(1)
      end

      it 'returns the duration when the timer is stopped' do
        t = timer.time
        expect(t.stop).to be_a(Fixnum)
      end

      it 'can time a block' do
        called = false
        timer.time { called = true }
        expect(called).to be_truthy
        expect(timer.count).to eq(1)
      end

      it 'returns the value of the block' do
        value = timer.time { :foo }
        expect(value).to eq(:foo)
      end
    end

    describe '#*_rate' do
      it 'knows the mean rate' do
        timer.update(3, :seconds)
        expect(timer.mean_rate).to be_a(Float)
      end

      it 'knows the one minute rate' do
        timer.update(3, :seconds)
        expect(timer.one_minute_rate).to be_a(Float)
      end

      it 'knows the five minute rate' do
        timer.update(3, :seconds)
        expect(timer.five_minute_rate).to be_a(Float)
      end

      it 'knows the fifteen minute rate' do
        timer.update(3, :seconds)
        expect(timer.fifteen_minute_rate).to be_a(Float)
      end
    end

    describe '#snapshot' do
      let :snapshot do
        timer.snapshot
      end

      before do
        timer.update(1, :seconds)
        timer.update(2, :seconds)
        timer.update(3, :seconds)
      end

      it 'knows the number of samples' do
        expect(snapshot.size).to eq(3)
      end

      it 'knows the maximum value' do
        expect(snapshot.max).to eq(3_000_000_000)
      end

      it 'knows the minimum value' do
        expect(snapshot.min).to eq(1_000_000_000)
      end

      it 'knows the mean' do
        expect(snapshot.mean).to eq(2_000_000_000.0)
      end

      it 'knows the median' do
        expect(snapshot.median).to eq(2_000_000_000.0)
      end

      it 'knows the standard deviation' do
        expect(snapshot.std_dev).to be_a(Numeric)
      end

      it 'has convenience accessors for common percentiles' do
        expect(snapshot.p75).to eq(3_000_000_000.0)
        expect(snapshot.p95).to eq(3_000_000_000.0)
        expect(snapshot.p98).to eq(3_000_000_000.0)
        expect(snapshot.p99).to eq(3_000_000_000.0)
        expect(snapshot.p999).to eq(3_000_000_000.0)
      end

      it 'can return a specific percentile' do
        expect(snapshot.value(0.50)).to eq(2_000_000_000.0)
      end

      it 'can return all the samples' do
        expect(snapshot.values).to eq([1_000_000_000, 2_000_000_000, 3_000_000_000])
      end
    end

    describe '#to_h' do
      it 'returns a hash representation of the timer' do
        timer.update(100, :milliseconds)
        h = timer.to_h
        expect(h[:type]).to eq(:timer)
        expect(h[:count]).to eq(1)
        expect(h[:mean_rate]).to be_a(Numeric)
        expect(h[:one_minute_rate]).to be_a(Numeric)
        expect(h[:five_minute_rate]).to be_a(Numeric)
        expect(h[:fifteen_minute_rate]).to be_a(Numeric)
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

      it 'scales the durations to milliseconds' do
        timer.update(1, :seconds)
        h = timer.to_h
        expect(h[:max]).to eq(1000.0)
        expect(h[:min]).to eq(1000.0)
        expect(h[:mean]).to eq(1000.0)
        expect(h[:median]).to eq(1000.0)
      end
    end
  end
end
