# encoding: utf-8

require 'spec_helper'

module Multimeter
  describe 'Multimeter.http' do
    let :registry do
      Multimeter.create_registry
    end

    context 'when handling requests' do
      def extract_app
        barrier = java.util.concurrent.Semaphore.new(0)
        app, options = nil, nil
        rack_handler = double(:rack_handler)
        allow(rack_handler).to receive(:run) do |a, o|
          app, options = a, o
          barrier.release
        end
        Multimeter.http(registry, rack_handler)
        expect(barrier.try_acquire(5, java.util.concurrent.TimeUnit::SECONDS)).not_to be_falsy
        [app, options]
      end

      before do
        registry.counter('test').inc
      end

      context 'valid requests' do
        it 'responds with a JSON document created from calling #to_h on the registry' do
          app, options = extract_app
          status, headers, body = app.call({'QUERY_STRING' => ''})
          expect(body.join("\n")).to eq('{"test":{"type":"counter","count":1}}')
        end

        it 'responds with application/json' do
          app, options = extract_app
          status, headers, body = app.call({'QUERY_STRING' => ''})
          expect(headers).to include('Content-Type' => 'application/json')
        end

        it 'responds with Connection: close' do
          app, options = extract_app
          status, headers, body = app.call({'QUERY_STRING' => ''})
          expect(headers).to include('Connection' => 'close')
        end

        it 'responds with CORS headers' do
          app, _ = extract_app
          _, headers, _ = app.call({'QUERY_STRING' => ''})
          expect(headers).to include('Access-Control-Allow-Origin' => '*')
        end

        context 'JSONP' do
          it 'responds with a JSON document wrapped in a function call when the callback parameter is given' do
            app, options = extract_app
            status, headers, body = app.call({'QUERY_STRING' => 'callback=the_cbk'})
            expect(body.join("\n")).to eq('the_cbk({"test":{"type":"counter","count":1}});')
          end

          it 'responds with application/javascript for JSONP request' do
            app, options = extract_app
            status, headers, body = app.call({'QUERY_STRING' => 'callback=the_cbk'})
            expect(headers).to include('Content-Type' => 'application/javascript')
          end

          it 'responds with Connection: close' do
            app, options = extract_app
            status, headers, body = app.call({'QUERY_STRING' => 'callback=the_cbk'})
            expect(headers).to include('Connection' => 'close')
          end
        end
      end

      context 'invalid requests' do
        context '400' do
          it 'responds with error 400 if the callback contains invalid chars' do
            app, options = extract_app
            status, headers, body = app.call({'QUERY_STRING' => 'callback=apa*&^%$'})
            expect(status).to eq(400)
          end

          it 'responds with Connection: close' do
            app, options = extract_app
            status, headers, body = app.call({'QUERY_STRING' => 'callback=apa*&^%$'})
            expect(headers).to include('Connection' => 'close')
          end
        end
        context '500' do
          it 'responds with error 500 if an exception is thrown in the request handling' do
            allow(registry).to receive(:to_h).and_raise('blurgh')
            app, options = extract_app
            status, headers, body = app.call({'QUERY_STRING' => 'callback=apa*&^%$'})
            expect(status).to eq(500)
          end

          it 'responds with Connection: close' do
            allow(registry).to receive(:to_h).and_raise('blurgh')
            app, options = extract_app
            status, headers, body = app.call({'QUERY_STRING' => 'callback=apa*&^%$'})
            expect(headers).to include('Connection' => 'close')
          end
        end
      end
    end
  end
end
