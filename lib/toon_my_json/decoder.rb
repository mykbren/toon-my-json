# frozen_string_literal: true

module ToonMyJson
  # Decodes TOON format back to Ruby objects
  class Decoder
    attr_reader :lines, :current_line, :delimiter

    def initialize(indent: 2, delimiter: ',')
      @indent_size = indent
      @delimiter = delimiter
    end

    def decode(toon_string)
      @lines = toon_string.split("\n")
      @current_line = 0

      # Detect if it's a single line
      if @lines.length == 1
        content = @lines[0].strip

        # Check if it's a key-value (check this first!)
        return parse_hash(0) if key_value_line?(content)

        # Check if it's a primitive array (contains delimiter but not quotes around everything)
        return parse_primitive_array(content) if content.include?(@delimiter) && !content.match(/^".*"$/)

        # Otherwise it's a single primitive
        return parse_primitive(content)
      end

      # Multi-line parsing
      parse_value(0)
    end

    private

    def parse_value(expected_indent)
      return nil if @current_line >= @lines.length

      line = @lines[@current_line]
      indent = get_indent(line)

      return nil if indent < expected_indent

      content = line.strip

      # Check for tabular array header [N]{fields}: or {fields}:
      return parse_tabular_array(indent) if content.match(/^(?:\[\d+\])?\{[^}]+\}:$/)

      # Check for list array (lines starting with -)
      return parse_list_array(indent) if content.start_with?('-')

      # Check if this looks like a hash (has key-value pairs)
      return parse_hash(indent) if key_value_line?(content)

      # Single primitive
      @current_line += 1
      parse_primitive(content)
    end

    def key_value_line?(line)
      # A key-value line has a colon, but the colon should not be inside quotes
      # Use split_key_value to check and avoid duplicate logic
      _, value = split_key_value(line)
      !value.nil?
    end

    def parse_hash(expected_indent)
      hash = {}

      while @current_line < @lines.length
        line = @lines[@current_line]
        indent = get_indent(line)

        break if indent < expected_indent

        content = line.strip
        break if content.empty?

        # Check if it's a tabular array header (not a key-value pair)
        break if content.match(/^(?:\[\d+\])?\{[^}]+\}:$/)

        # Check if it's a list array item
        break if content.start_with?('-')

        # Parse key-value pair
        key, value_part = split_key_value(content)
        if value_part.nil?
          # Not a valid key-value line (no unquoted colon), stop parsing hash
          break
        end

        key = parse_string(key.strip)

        if value_part.strip.empty?
          # Value on next lines (nested)
          @current_line += 1

          # Check if next line is a tabular array header (can be at any indent)
          if @current_line < @lines.length
            next_line = @lines[@current_line].strip
            if next_line.match(/^(?:\[\d+\])?\{[^}]+\}:$/)
              # Parse tabular array regardless of indent
              hash[key] = parse_tabular_array(get_indent(@lines[@current_line]))
              next
            end
          end

          # For nested values, accept same indent or greater
          hash[key] = parse_value(expected_indent)
        else
          # Value on same line
          value_part = value_part.strip
          @current_line += 1

          hash[key] = case value_part
                      when '[]'
                        []
                      when '{}'
                        {}
                      else
                        # Could be primitive, primitive array, or inline object
                        if value_part.include?(@delimiter) && !value_part.match(/^".*"$/)
                          # Primitive array
                          parse_primitive_array(value_part)
                        else
                          parse_primitive(value_part)
                        end
                      end
        end
      end

      hash
    end

    def split_key_value(line)
      # Split by first colon not in quotes
      in_quotes = false
      line.each_char.with_index do |char, i|
        if char == '"' && (i.zero? || line[i - 1] != '\\')
          in_quotes = !in_quotes
        elsif char == ':' && !in_quotes
          return [line[0...i], line[(i + 1)..]]
        end
      end
      [line, nil]
    end

    def parse_tabular_array(expected_indent)
      line = @lines[@current_line].strip

      # Parse header: [N]{field1,field2,...}: or {field1,field2,...}:
      match = line.match(/^(?:\[\d+\])?\{([^}]+)\}:$/)
      return [] unless match

      fields = match[1].split(@delimiter).map(&:strip)
      @current_line += 1

      array = []
      while @current_line < @lines.length
        line = @lines[@current_line]
        indent = get_indent(line)

        break if indent <= expected_indent

        content = line.strip
        break if content.empty?

        # Stop if we hit a key-value line (next section)
        break if key_value_line?(content) && !content.match(/^(?:\[\d+\])?\{[^}]+\}:$/)

        # Parse row
        values = parse_csv_line(content)
        row = {}
        fields.each_with_index do |field, i|
          row[field] = values[i] if i < values.length
        end
        array << row
        @current_line += 1
      end

      array
    end

    def parse_list_array(expected_indent)
      array = []

      while @current_line < @lines.length
        line = @lines[@current_line]
        indent = get_indent(line)

        break if indent < expected_indent

        content = line.strip
        break unless content.start_with?('-')

        # Remove leading dash and space
        item_content = content[1..].strip

        @current_line += 1
        array << if item_content.empty?
                   # Multi-line item (next line)
                   parse_value(expected_indent + @indent_size)
                 else
                   # Inline item
                   parse_primitive(item_content)
                 end
      end

      array
    end

    def parse_primitive_array(content)
      parse_csv_line(content)
    end

    def parse_csv_line(line)
      values = []
      current = String.new # Pre-allocate mutable string
      in_quotes = false
      i = 0

      while i < line.length
        char = line[i]

        if char == '"' && (i.zero? || line[i - 1] != '\\')
          in_quotes = !in_quotes
          current << char
        elsif char == @delimiter && !in_quotes
          values << parse_primitive(current.strip)
          current.clear
        else
          current << char
        end

        i += 1
      end

      values << parse_primitive(current.strip) unless current.strip.empty?
      values
    end

    def parse_primitive(value)
      value = value.strip

      # Handle quoted strings
      if value.start_with?('"') && value.end_with?('"') && value.length > 1
        # Remove quotes and unescape in single pass
        return unescape_string(value[1...-1])
      end

      # Handle special values
      case value
      when 'null'
        nil
      when 'true'
        true
      when 'false'
        false
      when /^-?\d+$/
        value.to_i
      when /^-?\d+\.\d+$/
        value.to_f
      else
        value
      end
    end

    def parse_string(value)
      if value.start_with?('"') && value.end_with?('"') && value.length > 1
        unescape_string(value[1...-1])
      else
        value
      end
    end

    def unescape_string(str)
      # Unescape only the specific escape sequences we support: \\ and \"
      str.gsub(/\\\\|\\"/) { |match| match == '\\\\' ? '\\' : '"' }
    end

    def get_indent(line)
      line.match(/^(\s*)/)[1].length
    end
  end
end
