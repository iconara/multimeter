require 'json'

shared_examples 'json-metrics' do
  let :metrics do
    JSON.parse(json)
  end

  it 'returns JSON' do
    expect { metrics }.not_to raise_error
  end

  shared_examples 'count' do
    it 'includes count' do
      expect(metric).to have_key('count')
    end
  end

  shared_examples 'rates' do
    {
      'm1_rate' => 'one minute rate',
      'm5_rate' => 'five minute rate',
      'm15_rate' => 'fifteen minute rate',
      'mean_rate' => 'mean rate',
    }.each do |key, name|
      it "includes the #{name}" do
        expect(metric).to have_key(key)
      end
    end
  end

  shared_examples 'histogram' do
    {
      'p50' => '50th percentile',
      'p75' => '75th percentile',
      'p95' => '95th percentile',
      'p98' => '98th percentile',
      'p99' => '99th percentile',
      'p999' => '99.9th percentile',
      'min' => 'minimum value',
      'max' => 'maximum value',
      'mean' => 'mean value',
      'stddev' => 'standard deviation',
    }.each do |key, name|
      it "includes the #{name}" do
        expect(metric).to have_key(key)
      end
    end
  end

  context 'with counters' do
    before do
      registry.counter('spec-counter').inc
    end

    let :metric do
      metrics['counters']['spec-counter']
    end

    include_examples 'count'
  end

  context 'with meters' do
    before do
      registry.meter('spec-meter').mark
    end

    let :metric do
      metrics['meters']['spec-meter']
    end

    include_examples 'count'
    include_examples 'rates'
  end

  context 'with histograms' do
    before do
      registry.histogram('spec-histogram').update(1)
    end

    let :metric do
      metrics['histograms']['spec-histogram']
    end

    include_examples 'histogram'
  end

  context 'with timers' do
    before do
      registry.timer('spec-timer').time {}
    end

    let :metric do
      metrics['timers']['spec-timer']
    end

    include_examples 'count'
    include_examples 'rates'
    include_examples 'histogram'
  end

  context 'with gauges' do
    before do
      registry.gauge('spec-gauge', :string) { 'a string' }
    end

    it 'inclues the value' do
      expect(metrics['gauges']['spec-gauge']).to include('value' => 'a string')
    end

    context "when type isn't specified" do
      before do
        registry.gauge('untyped-gauge') { -1 }
      end

      it 'failes to serialize' do
        expect { metrics }.to raise_error(JSON::ParserError)
      end
    end
  end
end