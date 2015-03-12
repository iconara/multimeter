# encoding: utf-8

require 'spec_helper'

module Multimeter
  describe Counter do
    let :counter do
      MetricRegistry.new.counter('a_counter')
    end

    describe '#inc/#dec/#count' do
      it 'has count zero initially' do
        expect(counter.count).to be_zero
      end

      it 'can be incremented' do
        counter.inc
        expect(counter.count).to eq(1)
      end

      it 'can be decremented' do
        counter.dec
        expect(counter.count).to eq(-1)
      end

      it 'can be incremented by a specific amount' do
        counter.inc(3)
        expect(counter.count).to eq(3)
      end

      it 'can be decremented by a specific amount' do
        counter.dec(3)
        expect(counter.count).to eq(-3)
      end
    end

    describe '#to_h' do
      it 'returns a hash representation of the counter' do
        counter.inc
        expect(counter.to_h).to eq(
          :type => :counter,
          :count => 1
        )
      end
    end
  end
end
