# encoding: utf-8

require 'spec_helper'
require 'support/json_metrics'

module Multimeter
  describe 'Multimeter.create_app' do
    let :registry do
      Multimeter.create_registry
    end

    let :app do
      Multimeter.create_app(registry)
    end

    context 'when handling' do
      context 'valid requests' do
        context 'responds with a JSON document that' do
          let :json do
            status, headers, body = app.call({'QUERY_STRING' => ''})
            body.join
          end

          include_examples 'json-metrics'
        end

        it 'responds with application/json' do
          status, headers, body = app.call({'QUERY_STRING' => ''})
          expect(headers).to include('Content-Type' => 'application/json')
        end

        it 'responds with Connection: close' do
          status, headers, body = app.call({'QUERY_STRING' => ''})
          expect(headers).to include('Connection' => 'close')
        end

        it 'responds with CORS headers' do
          _, headers, _ = app.call({'QUERY_STRING' => ''})
          expect(headers).to include('Access-Control-Allow-Origin' => '*')
        end

        context 'with a JSONP parameter' do
          let :env do
            { 'QUERY_STRING' => 'callback=the_cbk' }
          end

          it 'wraps the body in a function call' do
            status, headers, body = app.call(env)
            expect(body.join).to match(/\Athe_cbk\(.*\);\Z/)
          end

          it 'responds with a valid JSON document' do
            status, headers, body = app.call(env)
            json = body.join[/(?<=\Athe_cbk\().*(?=\);\Z)/]
            expect { JSON.parse(json) }.not_to raise_error
          end

          it 'responds with application/javascript for JSONP request' do
            status, headers, body = app.call(env)
            expect(headers).to include('Content-Type' => 'application/javascript')
          end

          it 'responds with Connection: close' do
            status, headers, body = app.call(env)
            expect(headers).to include('Connection' => 'close')
          end
        end
      end

      context 'invalid requests' do
        context '400' do
          it 'responds with error 400 if the callback contains invalid chars' do
            status, headers, body = app.call({'QUERY_STRING' => 'callback=apa*&^%$'})
            expect(status).to eq(400)
          end

          it 'responds with Connection: close' do
            status, headers, body = app.call({'QUERY_STRING' => 'callback=apa*&^%$'})
            expect(headers).to include('Connection' => 'close')
          end
        end

        context '500' do
          it 'responds with error 500 if an exception is thrown in the request handling' do
            allow(registry).to receive(:to_json).and_raise('blurgh')
            status, headers, body = app.call({'QUERY_STRING' => ''})
            expect(status).to eq(500)
          end

          it 'responds with Connection: close' do
            allow(registry).to receive(:to_json).and_raise('blurgh')
            status, headers, body = app.call({'QUERY_STRING' => ''})
            expect(headers).to include('Connection' => 'close')
          end
        end
      end
    end
  end
end
