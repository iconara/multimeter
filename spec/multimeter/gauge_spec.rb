# encoding: utf-8

require 'spec_helper'

module Multimeter
  describe Gauge do
    let :gauge do
      MetricRegistry.new.gauge('a_gauge', :int) { @value }
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

    describe '#to_json' do
      it 'returns a json representation of the gauge' do
        expect(JSON.parse(gauge.to_json)).to include('value' => 3)
      end

      context 'when the gauge is untyped' do
        let :gauge do
          MetricRegistry.new.gauge('b_gauge') { 1 }
        end

        it 'raises JsonMappingException' do
          expect { gauge.to_json }.to raise_error(Jackson::Databind::JsonMappingException)
        end
      end
    end
  end
end
