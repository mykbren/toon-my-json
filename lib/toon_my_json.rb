# frozen_string_literal: true

require_relative 'toon_my_json/version'
require_relative 'toon_my_json/encoder'
require_relative 'toon_my_json/decoder'
require 'json'

# ToonMyJson provides bidirectional conversion between JSON and TOON format.
# TOON (Token-Oriented Object Notation) is a compact serialization format
# designed for LLMs that reduces token usage by 30-60% compared to JSON.
module ToonMyJson
  class Error < StandardError; end

  # Convert a Ruby object or JSON string to TOON format
  #
  # @param input [String, Hash, Array, Object] JSON string or Ruby object
  # @param options [Hash] Encoding options
  # @option options [Integer] :indent Number of spaces per indentation level (default: 2)
  # @option options [String] :delimiter Field delimiter for arrays (',', '\t', or '|') (default: ',')
  # @option options [Boolean] :length_marker Include array length markers (default: true)
  # @return [String] TOON formatted string
  def self.encode(input, **options)
    data = if input.is_a?(String) && (input.start_with?('{', '[') || input.strip.start_with?('{', '['))
             begin
               JSON.parse(input)
             rescue JSON::ParserError
               input
             end
           else
             input
           end
    Encoder.new(**options).encode(data)
  end

  # Alias for encode
  def self.convert(input, **options)
    encode(input, **options)
  end

  # Convert TOON format string to Ruby object
  #
  # @param toon_string [String] TOON formatted string
  # @param options [Hash] Decoding options
  # @option options [Integer] :indent Number of spaces per indentation level (default: 2)
  # @option options [String] :delimiter Field delimiter for arrays (',', '\t', or '|') (default: ',')
  # @option options [Boolean] :json Return as JSON string instead of Ruby object (default: false)
  # @return [Hash, Array, Object, String] Ruby object or JSON string
  def self.decode(toon_string, **options)
    json_output = options.delete(:json)
    result = Decoder.new(**options).decode(toon_string)
    json_output ? JSON.pretty_generate(result) : result
  end
end
