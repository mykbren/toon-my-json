# frozen_string_literal: true

module ToonMyJson
  # Encodes Ruby objects to TOON format
  class Encoder
    RESERVED_CHARS = /[,:\[\]{}#\n\r\t]/
    NEEDS_QUOTES = /\A\s|\s\z|#{RESERVED_CHARS}/

    attr_reader :indent_size, :delimiter, :length_marker

    def initialize(indent: 2, delimiter: ',', length_marker: true)
      @indent_size = indent
      @delimiter = delimiter
      @length_marker = length_marker
    end

    def encode(value, depth = 0)
      case value
      when Hash
        encode_hash(value, depth)
      when Array
        encode_array(value, depth)
      when nil
        'null'
      when true, false
        value.to_s
      when Numeric
        value.to_s
      when String
        encode_string(value)
      else
        encode_string(value.to_s)
      end
    end

    private

    def encode_hash(hash, depth)
      return '{}' if hash.empty?

      lines = []
      hash.each do |key, value|
        encoded_value = encode_value_for_hash(value, depth)
        lines << "#{indent(depth)}#{encode_key(key)}:#{encoded_value}"
      end
      lines.join("\n")
    end

    def encode_value_for_hash(value, depth)
      case value
      when Hash
        if value.empty?
          ' {}'
        else
          "\n#{encode_hash(value, depth + 1)}"
        end
      when Array
        if value.empty?
          ' []'
        elsif uniform_array?(value) && value.first.is_a?(Hash)
          "\n#{encode_tabular_array(value, depth + 1)}"
        elsif primitive_array?(value)
          " #{encode_primitive_array(value)}"
        else
          "\n#{encode_list_array(value, depth + 1)}"
        end
      else
        " #{encode(value, depth)}"
      end
    end

    def encode_array(array, depth)
      return '[]' if array.empty?

      if uniform_array?(array) && array.first.is_a?(Hash)
        encode_tabular_array(array, depth)
      elsif primitive_array?(array)
        encode_primitive_array(array)
      else
        encode_list_array(array, depth)
      end
    end

    def encode_tabular_array(array, depth)
      return '[]' if array.empty?

      # Get all unique keys across all objects
      keys = array.flat_map(&:keys).uniq

      # Build header
      length_prefix = @length_marker ? "[#{array.length}]" : ''
      header = "#{length_prefix}{#{keys.join(delimiter)}}"

      # Build rows
      rows = array.map do |item|
        row_values = keys.map { |key| encode(item[key] || item[key.to_sym], depth) }
        "#{indent(depth)}#{row_values.join(delimiter)}"
      end

      "#{header}:\n#{rows.join("\n")}"
    end

    def encode_primitive_array(array)
      array.map { |v| encode(v, 0) }.join(delimiter)
    end

    def encode_list_array(array, depth)
      lines = array.map do |item|
        case item
        when Hash, Array
          encoded = encode(item, depth + 1)
          # If multiline, indent the nested structure
          if encoded.include?("\n")
            "#{indent(depth)}-\n#{indent_multiline(encoded, depth + 1)}"
          else
            "#{indent(depth)}- #{encoded}"
          end
        else
          "#{indent(depth)}- #{encode(item, depth)}"
        end
      end
      lines.join("\n")
    end

    def encode_key(key)
      key_str = key.to_s
      # Keys generally don't need quotes unless they contain special chars
      key_str.match?(NEEDS_QUOTES) ? encode_string(key_str) : key_str
    end

    def encode_string(str)
      return '""' if str.empty?

      # Check if string needs quotes
      if str.match?(NEEDS_QUOTES) || looks_like_number?(str) || looks_like_boolean?(str)
        # Escape quotes and backslashes
        escaped = str.gsub('\\', '\\\\\\\\').gsub('"', '\\"')
        "\"#{escaped}\""
      else
        str
      end
    end

    def uniform_array?(array)
      return false if array.empty? || !array.first.is_a?(Hash)

      # Check if all elements are hashes with similar structure
      first_keys = array.first.keys.sort
      min_overlap = (first_keys.length * 0.8).ceil

      array.all? do |item|
        next false unless item.is_a?(Hash)

        # Count matching keys without sorting every time
        overlap = 0
        item_keys = item.keys
        first_keys.each { |key| overlap += 1 if item_keys.include?(key) }
        overlap >= min_overlap
      end
    end

    def primitive_array?(array)
      array.all? { |v| v.is_a?(String) || v.is_a?(Numeric) || v == true || v == false || v.nil? }
    end

    def looks_like_number?(str)
      str.match?(/\A-?\d+(\.\d+)?\z/)
    end

    def looks_like_boolean?(str)
      %w[true false null].include?(str)
    end

    def indent(depth)
      ' ' * (depth * @indent_size)
    end

    def indent_multiline(text, depth)
      indent_str = indent(depth)
      text.gsub(/^/, indent_str)
    end
  end
end
