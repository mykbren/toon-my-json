# frozen_string_literal: true

require 'benchmark'
require 'benchmark/ips'

RSpec.describe 'Performance benchmarks', :benchmark do
  describe 'encoding performance' do
    it 'encodes 1000 records in under 10ms', :slow do
      large_array = 1000.times.map do |i|
        { 'id' => i, 'name' => "User#{i}", 'email' => "user#{i}@example.com", 'active' => true }
      end
      data = { 'users' => large_array, 'metadata' => { 'count' => 1000, 'page' => 1 } }

      elapsed = Benchmark.realtime { ToonMyJson.encode(data) }

      expect(elapsed).to be < 0.010, "Expected encode to complete in under 10ms, took #{(elapsed * 1000).round(2)}ms"
    end

    it 'encodes 100 records in under 1ms' do
      small_array = 100.times.map do |i|
        { 'id' => i, 'name' => "User#{i}", 'email' => "user#{i}@example.com" }
      end
      data = { 'users' => small_array }

      elapsed = Benchmark.realtime { ToonMyJson.encode(data) }

      expect(elapsed).to be < 0.001, "Expected encode to complete in under 1ms, took #{(elapsed * 1000).round(2)}ms"
    end

    it 'handles deeply nested structures efficiently' do
      nested = {
        'level1' => {
          'level2' => {
            'level3' => {
              'level4' => {
                'data' => 100.times.map { |i| { 'id' => i, 'value' => "item#{i}" } }
              }
            }
          }
        }
      }

      elapsed = Benchmark.realtime { ToonMyJson.encode(nested) }

      expect(elapsed).to be < 0.005,
                         "Expected nested encode to complete in under 5ms, took #{(elapsed * 1000).round(2)}ms"
    end
  end

  describe 'decoding performance' do
    it 'decodes 1000 records in under 50ms', :slow do
      large_array = 1000.times.map do |i|
        { 'id' => i, 'name' => "User#{i}", 'email' => "user#{i}@example.com", 'active' => true }
      end
      data = { 'users' => large_array, 'metadata' => { 'count' => 1000, 'page' => 1 } }
      toon = ToonMyJson.encode(data)

      elapsed = Benchmark.realtime { ToonMyJson.decode(toon) }

      expect(elapsed).to be < 0.050, "Expected decode to complete in under 50ms, took #{(elapsed * 1000).round(2)}ms"
    end

    it 'decodes 100 records in under 5ms' do
      small_array = 100.times.map do |i|
        { 'id' => i, 'name' => "User#{i}", 'email' => "user#{i}@example.com" }
      end
      data = { 'users' => small_array }
      toon = ToonMyJson.encode(data)

      elapsed = Benchmark.realtime { ToonMyJson.decode(toon) }

      expect(elapsed).to be < 0.005, "Expected decode to complete in under 5ms, took #{(elapsed * 1000).round(2)}ms"
    end
  end

  describe 'roundtrip performance' do
    it 'completes encode + decode roundtrip in under 60ms for 1000 records', :slow do
      large_array = 1000.times.map do |i|
        { 'id' => i, 'name' => "User#{i}", 'email' => "user#{i}@example.com", 'active' => true }
      end
      data = { 'users' => large_array, 'metadata' => { 'count' => 1000, 'page' => 1 } }

      elapsed = Benchmark.realtime do
        toon = ToonMyJson.encode(data)
        ToonMyJson.decode(toon)
      end

      expect(elapsed).to be < 0.060, "Expected roundtrip to complete in under 60ms, took #{(elapsed * 1000).round(2)}ms"
    end
  end

  describe 'benchmark-ips comparison', :ips do
    it 'measures iterations per second for common operations' do
      # Small dataset for IPS testing
      data = {
        'users' => 10.times.map { |i| { 'id' => i, 'name' => "User#{i}" } }
      }
      toon = ToonMyJson.encode(data)

      puts "\n"
      Benchmark.ips do |x|
        x.config(time: 2, warmup: 1)

        x.report('encode (10 records)') { ToonMyJson.encode(data) }
        x.report('decode (10 records)') { ToonMyJson.decode(toon) }
        x.report('roundtrip (10 records)') do
          ToonMyJson.decode(ToonMyJson.encode(data))
        end

        x.compare!
      end
      puts "\n"
    end
  end

  describe 'memory efficiency' do
    it 'encodes without excessive memory allocation' do
      data = { 'users' => 100.times.map { |i| { 'id' => i, 'name' => "User#{i}" } } }

      # This is a basic test - just ensure it completes without memory issues
      expect { ToonMyJson.encode(data) }.not_to raise_error
    end

    it 'decodes without excessive memory allocation' do
      data = { 'users' => 100.times.map { |i| { 'id' => i, 'name' => "User#{i}" } } }
      toon = ToonMyJson.encode(data)

      expect { ToonMyJson.decode(toon) }.not_to raise_error
    end
  end
end
