# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ToonMyJson, '.decode' do
  describe 'primitives' do
    it 'decodes numbers' do
      expect(ToonMyJson.decode('42')).to eq(42)
      expect(ToonMyJson.decode('3.14')).to eq(3.14)
    end

    it 'decodes booleans' do
      expect(ToonMyJson.decode('true')).to eq(true)
      expect(ToonMyJson.decode('false')).to eq(false)
    end

    it 'decodes null' do
      expect(ToonMyJson.decode('null')).to be_nil
    end

    it 'decodes simple strings' do
      expect(ToonMyJson.decode('hello')).to eq('hello')
    end

    it 'decodes multiline with standalone primitive' do
      toon = <<~TOON.chomp
        test
        another
      TOON
      # When there's no structure (no colons, no dashes), it tries to parse as value
      result = ToonMyJson.decode(toon)
      # First line is parsed, second line causes break
      expect(result).to eq('test')
    end
  end

  describe 'quoted strings' do
    it 'decodes quoted strings with special characters' do
      expect(ToonMyJson.decode('"hello, world"')).to eq('hello, world')
      expect(ToonMyJson.decode('"hello:world"')).to eq('hello:world')
    end

    it 'handles keys with colons in quotes' do
      toon = '"key:with:colons": value'
      result = ToonMyJson.decode(toon)
      expect(result['key:with:colons']).to eq('value')
    end
  end

  describe 'primitive arrays' do
    it 'decodes comma-separated values' do
      toon = '1,2,3'
      expect(ToonMyJson.decode(toon)).to eq([1, 2, 3])
    end

    it 'decodes arrays with quoted values containing delimiters' do
      toon = 'a,"b,c",d'
      expect(ToonMyJson.decode(toon)).to eq(['a', 'b,c', 'd'])
    end
  end

  describe 'simple hashes' do
    it 'decodes key-value pairs' do
      toon = <<~TOON.chomp
        name: Alice
        age: 30
      TOON

      result = ToonMyJson.decode(toon)
      expect(result['name']).to eq('Alice')
      expect(result['age']).to eq(30)
    end

    it 'stops parsing hash when encountering tabular array header at same level' do
      toon = <<~TOON.chomp
        key: value
        [1]{id}:
          1
      TOON

      result = ToonMyJson.decode(toon)
      # Hash parsing should stop at the tabular array header
      expect(result).to be_a(Hash)
      expect(result['key']).to eq('value')
      expect(result.keys.length).to eq(1)
    end

    it 'stops parsing hash when encountering list item at same level' do
      toon = <<~TOON.chomp
        key: value
        - item
      TOON

      result = ToonMyJson.decode(toon)
      # Hash parsing should stop at the list item
      expect(result).to be_a(Hash)
      expect(result['key']).to eq('value')
      expect(result.keys.length).to eq(1)
    end

    it 'handles keys without colons' do
      toon = 'keywithnocolon'
      result = ToonMyJson.decode(toon)
      # When there's no colon, split_key_value returns [line, nil]
      expect(result).to eq('keywithnocolon')
    end

    it 'stops parsing hash when encountering line without colon' do
      toon = <<~TOON.chomp
        key1: value1
        key2: value2
        linewithnocolon
        key3: value3
      TOON

      result = ToonMyJson.decode(toon)
      # Hash parsing should stop at the line without colon
      expect(result).to be_a(Hash)
      expect(result['key1']).to eq('value1')
      expect(result['key2']).to eq('value2')
      expect(result.keys.length).to eq(2)
      expect(result['key3']).to be_nil
    end
  end

  describe 'nested hashes' do
    it 'decodes nested structures' do
      toon = <<~TOON.chomp
        user:
          name: Alice
          age: 30
      TOON

      result = ToonMyJson.decode(toon)
      expect(result['user']).to be_a(Hash)
      expect(result['user']['name']).to eq('Alice')
      expect(result['user']['age']).to eq(30)
    end
  end

  describe 'hashes with primitive arrays' do
    it 'decodes inline arrays' do
      toon = 'colors: red,green,blue'

      result = ToonMyJson.decode(toon)
      expect(result['colors']).to eq(%w[red green blue])
    end
  end

  describe 'tabular arrays' do
    context 'with length marker' do
      it 'decodes tabular format with length marker' do
        toon = <<~TOON.chomp
          [2]{id,name,role}:
            1,Alice,admin
            2,Bob,user
        TOON

        result = ToonMyJson.decode(toon)
        expect(result).to be_an(Array)
        expect(result.length).to eq(2)
        expect(result[0]['id']).to eq(1)
        expect(result[0]['name']).to eq('Alice')
        expect(result[0]['role']).to eq('admin')
        expect(result[1]['id']).to eq(2)
        expect(result[1]['name']).to eq('Bob')
        expect(result[1]['role']).to eq('user')
      end
    end

    context 'without length marker' do
      it 'decodes tabular format without length marker' do
        toon = <<~TOON.chomp
          {id,name,role}:
            1,Alice,admin
            2,Bob,user
        TOON

        result = ToonMyJson.decode(toon)
        expect(result).to be_an(Array)
        expect(result.length).to eq(2)
        expect(result[0]['id']).to eq(1)
        expect(result[0]['name']).to eq('Alice')
      end
    end

    context 'within hashes' do
      it 'decodes nested tabular arrays' do
        toon = <<~TOON.chomp
          users:
          [2]{id,name,role}:
            1,Alice,admin
            2,Bob,user
        TOON

        result = ToonMyJson.decode(toon)
        expect(result['users']).to be_an(Array)
        expect(result['users'].length).to eq(2)
        expect(result['users'][0]['name']).to eq('Alice')
      end
    end
  end

  describe 'empty containers' do
    it 'decodes empty arrays' do
      expect(ToonMyJson.decode('items: []')).to eq({ 'items' => [] })
    end

    it 'decodes empty hashes' do
      expect(ToonMyJson.decode('data: {}')).to eq({ 'data' => {} })
    end
  end

  describe 'list arrays' do
    it 'decodes dash-prefixed lists' do
      toon = <<~TOON.chomp
        - string
        - 42
        - true
      TOON

      result = ToonMyJson.decode(toon)
      expect(result).to eq(['string', 42, true])
    end

    it 'decodes list array with inline empty containers' do
      toon = <<~TOON.chomp
        - item
        - {}
        - []
      TOON

      result = ToonMyJson.decode(toon)
      # Empty containers as inline values are treated as strings
      expect(result).to eq(['item', '{}', '[]'])
    end

    it 'decodes list array with nested structures' do
      toon = <<~TOON.chomp
        -
          nested:
            key: value
      TOON

      result = ToonMyJson.decode(toon)
      expect(result[0]).to be_a(Hash)
      expect(result[0]['nested']['key']).to eq('value')
    end
  end

  describe 'complex structures' do
    it 'decodes nested structures with mixed types' do
      toon = <<~TOON.chomp
        company: TechCorp
        employees:
        [2]{id,name,department}:
          1,Alice,Engineering
          2,Bob,Sales
        metadata:
          founded: 2020
          location: San Francisco
      TOON

      result = ToonMyJson.decode(toon)
      expect(result['company']).to eq('TechCorp')
      expect(result['employees']).to be_an(Array)
      expect(result['employees'].length).to eq(2)
      expect(result['employees'][0]['name']).to eq('Alice')
      expect(result['employees'][0]['department']).to eq('Engineering')
      expect(result['metadata']).to be_a(Hash)
      expect(result['metadata']['founded']).to eq(2020)
      expect(result['metadata']['location']).to eq('San Francisco')
    end
  end

  describe 'JSON output option' do
    it 'returns JSON string when json: true' do
      toon = "name: Alice\nage: 30"
      result = ToonMyJson.decode(toon, json: true)

      expect(result).to be_a(String)
      parsed = JSON.parse(result)
      expect(parsed['name']).to eq('Alice')
      expect(parsed['age']).to eq(30)
    end
  end

  describe 'roundtrip conversions' do
    context 'with simple data' do
      it 'maintains data integrity' do
        original = { 'name' => 'Alice', 'age' => 30 }
        toon = ToonMyJson.encode(original)
        decoded = ToonMyJson.decode(toon)

        expect(decoded).to eq(original)
      end
    end

    context 'with arrays of objects' do
      it 'preserves array structure' do
        original = {
          'users' => [
            { 'id' => 1, 'name' => 'Alice', 'role' => 'admin' },
            { 'id' => 2, 'name' => 'Bob', 'role' => 'user' }
          ]
        }
        toon = ToonMyJson.encode(original)
        decoded = ToonMyJson.decode(toon)

        expect(decoded).to eq(original)
      end
    end

    context 'with complex nested data' do
      it 'handles multiple levels of nesting' do
        original = {
          'company' => 'TechCorp',
          'employees' => [
            { 'id' => 1, 'name' => 'Alice', 'department' => 'Engineering' },
            { 'id' => 2, 'name' => 'Bob', 'department' => 'Sales' }
          ],
          'metadata' => {
            'founded' => 2020,
            'location' => 'San Francisco'
          },
          'tags' => %w[tech startup ai]
        }

        toon = ToonMyJson.encode(original)
        decoded = ToonMyJson.decode(toon)

        expect(decoded).to eq(original)
      end
    end
  end

  describe 'custom delimiter option' do
    it 'uses specified delimiter' do
      toon = 'colors: red|green|blue'
      result = ToonMyJson.decode(toon, delimiter: '|')

      expect(result['colors']).to eq(%w[red green blue])
    end
  end

  describe 'quoted numbers' do
    it 'preserves quoted numbers as strings' do
      toon = <<~TOON.chomp
        id: "123"
        code: "456"
      TOON

      result = ToonMyJson.decode(toon)
      expect(result['id']).to eq('123')
      expect(result['code']).to eq('456')
    end
  end

  describe 'branch coverage edge cases' do
    it 'decodes single value that is a quoted string with delimiter' do
      toon = '"value,with,commas"'
      result = ToonMyJson.decode(toon)
      expect(result).to eq('value,with,commas')
    end

    it 'decodes escaped quotes in string' do
      toon = 'key: "value with \\"quotes\\""'
      result = ToonMyJson.decode(toon)
      expect(result['key']).to eq('value with "quotes"')
    end

    it 'decodes escaped backslashes' do
      toon = 'path: "C:\\\\Users\\\\test"'
      result = ToonMyJson.decode(toon)
      expect(result['path']).to eq('C:\\Users\\test')
    end

    it 'decodes floats' do
      toon = 'value: 3.14'
      result = ToonMyJson.decode(toon)
      expect(result['value']).to eq(3.14)
    end

    it 'decodes negative integers' do
      toon = 'value: -42'
      result = ToonMyJson.decode(toon)
      expect(result['value']).to eq(-42)
    end

    it 'decodes negative floats' do
      toon = 'value: -3.14'
      result = ToonMyJson.decode(toon)
      expect(result['value']).to eq(-3.14)
    end

    it 'decodes quoted string with length 1' do
      toon = 'key: "a"'
      result = ToonMyJson.decode(toon)
      expect(result['key']).to eq('a')
    end

    it 'decodes tabular array that stops at key-value line' do
      toon = <<~TOON.chomp
        {id,name}:
          1,Alice
          2,Bob
        nextkey: value
      TOON

      result = ToonMyJson.decode(toon)
      expect(result).to be_an(Array)
      expect(result.length).to eq(2)
    end

    it 'decodes CSV with trailing empty value' do
      toon = 'values: a,b,'
      result = ToonMyJson.decode(toon)
      expect(result['values']).to eq(%w[a b])
    end

    it 'decodes tabular array with missing field values' do
      toon = <<~TOON.chomp
        {id,name,role}:
          1,Alice
          2,Bob,admin
      TOON

      result = ToonMyJson.decode(toon)
      expect(result[0]['role']).to be_nil
      expect(result[1]['role']).to eq('admin')
    end

    it 'handles indent less than expected in parse_value' do
      toon = <<~TOON.chomp
        outer:
          inner: value
        sameLevelKey: value2
      TOON

      result = ToonMyJson.decode(toon)
      expect(result['outer']['inner']).to eq('value')
      expect(result['sameLevelKey']).to eq('value2')
    end

    it 'decodes empty quoted string in primitive' do
      toon = 'key: ""'
      result = ToonMyJson.decode(toon)
      expect(result['key']).to eq('')
    end

    it 'handles colon at start of line in quotes' do
      toon = 'key: ":value"'
      result = ToonMyJson.decode(toon)
      expect(result['key']).to eq(':value')
    end

    it 'handles escaped quote at position 0' do
      # This tests the edge case where i == 0 in the escape check
      toon = 'values: "test",value'
      result = ToonMyJson.decode(toon)
      expect(result['values']).to include('test')
      expect(result['values']).to include('value')
    end

    it 'handles quote at position 0 in split_key_value' do
      toon = '"quoted:key": value'
      result = ToonMyJson.decode(toon)
      expect(result['quoted:key']).to eq('value')
    end

    it 'decodes when current_line equals lines.length in parse_value' do
      # Test the boundary condition
      toon = "key: value\n"
      result = ToonMyJson.decode(toon)
      expect(result['key']).to eq('value')
    end

    it 'handles list with only dashes and content' do
      toon = <<~TOON.chomp
        - item1
        - item2
      TOON
      result = ToonMyJson.decode(toon)
      expect(result).to eq(%w[item1 item2])
    end

    it 'decodes value with unescaped backslash followed by non-quote' do
      toon = 'path: "C:\\test"'
      result = ToonMyJson.decode(toon)
      # Single backslash followed by t should remain as is in the unescape
      expect(result['path']).to eq('C:\\test')
    end

    it 'handles empty line during hash parsing' do
      toon = <<~TOON.chomp
        key1: value1

        key2: value2
      TOON
      result = ToonMyJson.decode(toon)
      # Empty line should stop hash parsing
      expect(result).to be_a(Hash)
      expect(result['key1']).to eq('value1')
      expect(result['key2']).to be_nil
    end

    it 'handles indent exactly at expected level in parse_list_array' do
      toon = <<~TOON.chomp
        -
          nested: value
      TOON
      result = ToonMyJson.decode(toon)
      expect(result[0]['nested']).to eq('value')
    end

    it 'handles tabular array with indent less than or equal to expected' do
      toon = <<~TOON.chomp
        {id,name}:
          1,Alice
        2,Bob
      TOON
      result = ToonMyJson.decode(toon)
      # Should stop at line with indent <= expected
      expect(result.length).to eq(1)
    end

    it 'handles quoted string in parse_string with length > 1' do
      toon = 'key: "ab"'
      result = ToonMyJson.decode(toon)
      expect(result['key']).to eq('ab')
    end

    it 'handles quoted string in parse_string at boundary' do
      toon = 'key: "a' # Malformed, but tests the length check
      result = ToonMyJson.decode(toon)
      expect(result['key']).to eq('"a') # Not properly quoted, treated as string
    end

    it 'handles non-quoted string in parse_string' do
      toon = 'normalkey: normalvalue'
      result = ToonMyJson.decode(toon)
      expect(result['normalkey']).to eq('normalvalue')
    end

    it 'decodes value matching integer regex' do
      toon = 'num: 42'
      result = ToonMyJson.decode(toon)
      expect(result['num']).to eq(42)
      expect(result['num']).to be_a(Integer)
    end

    it 'decodes value matching float regex' do
      toon = 'num: 3.14159'
      result = ToonMyJson.decode(toon)
      expect(result['num']).to eq(3.14159)
      expect(result['num']).to be_a(Float)
    end

    it 'decodes value not matching any special case' do
      toon = 'text: regularstring'
      result = ToonMyJson.decode(toon)
      expect(result['text']).to eq('regularstring')
      expect(result['text']).to be_a(String)
    end

    it 'handles backslash before quote in split_key_value' do
      # Test the escape check: i == 0 || line[i-1] != '\\'
      # This tests when line[i-1] == '\\'
      toon = 'key\\": value'
      result = ToonMyJson.decode(toon)
      # The backslash-quote should not be treated as a delimiter
      expect(result).to be_a(Hash)
    end

    it 'decodes value with backslash not followed by quote' do
      toon = 'path: "C:\\folder"'
      result = ToonMyJson.decode(toon)
      expect(result['path']).to eq('C:\\folder')
    end

    it 'handles value starting with quote but not ending' do
      toon = 'key: "unclosed'
      result = ToonMyJson.decode(toon)
      # Not properly quoted, treated as string
      expect(result['key']).to eq('"unclosed')
    end

    it 'handles value ending with quote but not starting' do
      toon = 'key: unclosed"'
      result = ToonMyJson.decode(toon)
      expect(result['key']).to eq('unclosed"')
    end

    it 'handles empty value in primitive parsing' do
      # This tests when value.strip is empty but gets to parse_primitive
      toon = 'items: a,,b'
      result = ToonMyJson.decode(toon)
      # CSV parsing should handle empty values
      expect(result['items']).to include('a')
      expect(result['items']).to include('b')
    end

    it 'handles single character quoted value' do
      toon = 'key: "x"'
      result = ToonMyJson.decode(toon)
      expect(result['key']).to eq('x')
    end

    it 'decodes value starting and ending with quote but length 1' do
      toon = 'quote: "'
      result = ToonMyJson.decode(toon)
      # Single quote doesn't meet length > 1 requirement
      expect(result['quote']).to eq('"')
    end

    it 'handles backslash at end of string in CSV' do
      toon = 'items: "test\\",value'
      result = ToonMyJson.decode(toon)
      expect(result['items']).to be_an(Array)
    end

    it 'handles quote at position 0 in CSV parsing' do
      # Tests i == 0 branch in parse_csv_line
      toon = 'items: "first",second'
      result = ToonMyJson.decode(toon)
      expect(result['items'][0]).to eq('first')
      expect(result['items'][1]).to eq('second')
    end

    it 'handles escaped quote in middle of CSV value' do
      # Tests line[i-1] == '\\' branch
      # Use proper Ruby escaping
      toon = 'items: test\\"value,other'
      result = ToonMyJson.decode(toon)
      expect(result['items']).to be_an(Array)
    end

    it 'handles non-quote character at position 0 in CSV' do
      toon = 'items: a,b,c'
      result = ToonMyJson.decode(toon)
      expect(result['items']).to eq(%w[a b c])
    end

    it 'handles delimiter when not in quotes in CSV' do
      # Tests the elsif char == @delimiter && !in_quotes branch
      toon = 'items: a,b,c'
      result = ToonMyJson.decode(toon)
      expect(result['items'].length).to eq(3)
    end

    it 'handles delimiter when inside quotes in CSV' do
      # in_quotes is true, so delimiter is added to current
      toon = 'items: "a,b",c'
      result = ToonMyJson.decode(toon)
      expect(result['items'][0]).to eq('a,b')
      expect(result['items'][1]).to eq('c')
    end

    it 'handles regular characters in CSV' do
      # Tests the else branch in parse_csv_line
      toon = 'items: abc,def'
      result = ToonMyJson.decode(toon)
      expect(result['items']).to include('abc')
      expect(result['items']).to include('def')
    end

    it 'handles single line with delimiter but fully quoted' do
      # Tests content.include?(@delimiter) && !content.match(/^".*"$/)
      # When content is fully quoted, should NOT be parsed as array
      toon = '"this,has,commas"'
      result = ToonMyJson.decode(toon)
      expect(result).to eq('this,has,commas')
    end

    it 'handles single line with delimiter not fully quoted' do
      # When content has delimiter and is NOT fully quoted
      toon = 'partial"quote,value'
      result = ToonMyJson.decode(toon)
      # Should parse as array
      expect(result).to be_an(Array)
    end

    it 'handles value with quotes that starts but not ends properly' do
      # value.start_with?('"') is true, but other conditions fail
      toon = 'key: "starts'
      result = ToonMyJson.decode(toon)
      expect(result['key']).to eq('"starts')
    end

    it 'handles value with quotes that ends but not starts' do
      # value.end_with?('"') is true but start_with? is false
      toon = 'key: ends"'
      result = ToonMyJson.decode(toon)
      expect(result['key']).to eq('ends"')
    end

    it 'handles empty value part that is stripped to empty' do
      # value_part.strip.empty? returns true
      toon = "key:   \n  nested: value"
      result = ToonMyJson.decode(toon)
      expect(result['key']['nested']).to eq('value')
    end

    it 'handles value_part with delimiter and not quoted' do
      # Tests value_part.include?(@delimiter) && !value_part.match(/^".*"$/)
      toon = 'key: a,b,c'
      result = ToonMyJson.decode(toon)
      expect(result['key']).to be_an(Array)
    end

    it 'handles value_part with delimiter but fully quoted' do
      # Delimiter present but fully quoted - should not be parsed as array
      toon = 'key: "a,b,c"'
      result = ToonMyJson.decode(toon)
      expect(result['key']).to eq('a,b,c')
    end

    it 'handles key-value line that is not tabular array header' do
      # Tests is_key_value_line?(content) && !content.match tabular regex
      toon = <<~TOON.chomp
        {id,name}:
          1,Alice
        regular: value
      TOON
      result = ToonMyJson.decode(toon)
      # Should stop tabular parsing at 'regular: value'
      expect(result).to be_an(Array)
    end

    it 'covers all branches in parse_primitive for quoted strings' do
      decoder = ToonMyJson::Decoder.new

      # value.start_with?('"') is true, end_with?('"') is true, length > 1 is true
      result1 = decoder.send(:parse_primitive, '"quoted"')
      expect(result1).to eq('quoted')

      # value.start_with?('"') is true, end_with?('"') is true, but length = 2 (edge)
      result2 = decoder.send(:parse_primitive, '""')
      expect(result2).to eq('')

      # value.start_with?('"') is true, but end_with?('"') is false
      result3 = decoder.send(:parse_primitive, '"noend')
      expect(result3).to eq('"noend')

      # value.start_with?('"') is false
      result4 = decoder.send(:parse_primitive, 'nostart"')
      expect(result4).to eq('nostart"')

      # Single quote character - start and end true but length = 1
      result5 = decoder.send(:parse_primitive, '"')
      expect(result5).to eq('"')
    end

    it 'covers all case branches in parse_primitive' do
      decoder = ToonMyJson::Decoder.new

      # Test 'null' case
      expect(decoder.send(:parse_primitive, 'null')).to be_nil

      # Test 'true' case
      expect(decoder.send(:parse_primitive, 'true')).to eq(true)

      # Test 'false' case
      expect(decoder.send(:parse_primitive, 'false')).to eq(false)

      # Test integer regex match
      expect(decoder.send(:parse_primitive, '42')).to eq(42)
      expect(decoder.send(:parse_primitive, '-42')).to eq(-42)

      # Test float regex match
      expect(decoder.send(:parse_primitive, '3.14')).to eq(3.14)
      expect(decoder.send(:parse_primitive, '-3.14')).to eq(-3.14)

      # Test else (no match)
      expect(decoder.send(:parse_primitive, 'text')).to eq('text')
    end

    it 'covers parse_string with quoted and unquoted strings' do
      decoder = ToonMyJson::Decoder.new

      # Quoted string with length > 1
      result1 = decoder.send(:parse_string, '"quoted"')
      expect(result1).to eq('quoted')

      # Unquoted string
      result2 = decoder.send(:parse_string, 'unquoted')
      expect(result2).to eq('unquoted')

      # Edge case: two quotes (length = 2)
      result3 = decoder.send(:parse_string, '""')
      expect(result3).to eq('')

      # Single quote (length = 1, fails length > 1 check)
      result4 = decoder.send(:parse_string, '"')
      expect(result4).to eq('"')
    end

    it 'covers split_key_value with quote at different positions' do
      decoder = ToonMyJson::Decoder.new

      # Quote at position 0 (i == 0 branch)
      key, val = decoder.send(:split_key_value, '"key:quoted": value')
      expect(key).to eq('"key:quoted"')
      expect(val).to eq(' value')

      # Quote after position 0 without backslash before it
      # When quote is in the middle, it tracks in_quotes
      _, val = decoder.send(:split_key_value, 'key: "value:with:colon"')
      expect(val).to be_truthy

      # Escaped quote (backslash before it)
      # This tests i > 0 && line[i-1] == '\\'
      _, val = decoder.send(:split_key_value, 'key\\":value')
      # The \" should not trigger quote tracking
      expect(val).to eq('value')
    end

    it 'covers parse_csv_line with all char scenarios' do
      decoder = ToonMyJson::Decoder.new

      # Quote at position 0
      result1 = decoder.send(:parse_csv_line, '"a",b')
      expect(result1).to eq(%w[a b])

      # Quote at position > 0, no backslash before
      result2 = decoder.send(:parse_csv_line, 'x"y,z')
      expect(result2).to be_an(Array)
      expect(result2.first).to include('x"y')

      # Delimiter outside quotes
      result3 = decoder.send(:parse_csv_line, 'a,b,c')
      expect(result3).to eq(%w[a b c])

      # Delimiter inside quotes (should be kept)
      result4 = decoder.send(:parse_csv_line, '"a,b",c')
      expect(result4[0]).to eq('a,b')

      # Regular character (else branch)
      result5 = decoder.send(:parse_csv_line, 'abc')
      expect(result5).to eq(['abc'])
    end

    it 'covers parse_value when current_line exceeds lines.length' do
      # This hits the return nil if @current_line >= @lines.length branch
      decoder = ToonMyJson::Decoder.new

      # Decode something simple first to initialize
      decoder.decode('key: value')

      # Now manually set @current_line beyond the array
      decoder.instance_variable_set(:@current_line, 999)

      # Call parse_value - should return nil
      result = decoder.send(:parse_value, 0)
      expect(result).to be_nil
    end

    it 'covers parse_value when indent is less than expected' do
      # This hits the return nil if indent < expected_indent branch
      decoder = ToonMyJson::Decoder.new

      # Set up a scenario where we're parsing with expected indent 4
      # but current line has indent 0
      toon = "  nested: value\nbacklevel: value2"
      decoder.instance_variable_set(:@lines, toon.split("\n"))
      decoder.instance_variable_set(:@current_line, 1) # Point to "backlevel" line

      # Call parse_value expecting indent of 4, but line has indent 0
      result = decoder.send(:parse_value, 4)
      expect(result).to be_nil
    end

    it 'covers parse_tabular_array when header has no match' do
      # This hits the return [] unless match branch at line 165
      decoder = ToonMyJson::Decoder.new

      # Set up invalid tabular array header (no match)
      decoder.instance_variable_set(:@lines, ['invalid_header'])
      decoder.instance_variable_set(:@current_line, 0)

      result = decoder.send(:parse_tabular_array, 0)
      expect(result).to eq([])
    end

    it 'covers parse_tabular_array break on indent <= expected' do
      # This hits the break if indent <= expected_indent branch at line 175
      toon = <<~TOON.chomp
        {id,name}:
          1,Alice
        2,Bob
      TOON

      result = ToonMyJson.decode(toon)
      # Should stop parsing when indent goes back to 0 (less than or equal to expected indent of 0)
      expect(result).to be_an(Array)
      expect(result.length).to eq(1)
    end

    it 'covers parse_tabular_array break on empty content' do
      # This hits the break if content.empty? branch at line 178
      toon = <<~TOON.chomp
        {id,name}:
          1,Alice

      TOON

      result = ToonMyJson.decode(toon)
      expect(result).to be_an(Array)
    end

    it 'covers parse_list_array break on indent less than expected' do
      # This hits the break if indent < expected_indent branch at line 203
      toon = <<~TOON.chomp
        outer:
          - item1
          - item2
        nextkey: value
      TOON

      result = ToonMyJson.decode(toon)
      expect(result['outer']).to be_an(Array)
      expect(result['nextkey']).to eq('value')
    end

    it 'covers parse_list_array break when line does not start with dash' do
      # This hits the break unless content.start_with?('-') branch at line 206
      toon = <<~TOON.chomp
        - item1
        - item2
        notdash
      TOON

      result = ToonMyJson.decode(toon)
      expect(result).to be_an(Array)
      expect(result.length).to eq(2)
    end

    it 'covers parse_tabular_array when current_line reaches end of lines' do
      # This hits the while @current_line < @lines.length condition at line 171
      # When loop exits naturally because we've processed all lines
      toon = <<~TOON.chomp
        {id,name}:
          1,Alice
          2,Bob
      TOON

      result = ToonMyJson.decode(toon)
      # All lines processed, loop exits naturally when @current_line >= @lines.length
      expect(result).to be_an(Array)
      expect(result.length).to eq(2)
    end

    it 'covers parse_tabular_array break on empty content' do
      # This hits the break if content.empty? branch at line 178
      # Need empty line AFTER header, during row parsing
      decoder = ToonMyJson::Decoder.new

      # Manually set up the state
      toon_lines = [
        '{id,name}:',
        '  1,Alice',
        '  ', # Empty content after stripping
        '  2,Bob'
      ]

      decoder.instance_variable_set(:@lines, toon_lines)
      decoder.instance_variable_set(:@current_line, 0)

      result = decoder.send(:parse_tabular_array, 0)
      # Should stop at empty line
      expect(result).to be_an(Array)
      expect(result.length).to eq(1) # Only first row before empty line
    end

    it 'covers parse_tabular_array break on key-value line that is not tabular header' do
      # This hits the break if is_key_value_line?(content) && !content.match(...) branch at line 181
      # Need a line with colon that is NOT a tabular array header
      decoder = ToonMyJson::Decoder.new

      toon_lines = [
        '{id,name}:',
        '  1,Alice',
        '  nextkey: value', # Key-value line, NOT tabular header
        '  2,Bob'
      ]

      decoder.instance_variable_set(:@lines, toon_lines)
      decoder.instance_variable_set(:@current_line, 0)

      result = decoder.send(:parse_tabular_array, 0)
      # Should stop at key-value line
      expect(result).to be_an(Array)
      expect(result.length).to eq(1) # Only first row before key-value line
    end

    it 'covers parse_hash when current_line reaches end after empty value' do
      # This covers the else branch at line 111-118 when @current_line >= @lines.length
      # after encountering a key with empty value
      toon = 'key:'
      result = ToonMyJson.decode(toon)
      expect(result).to eq({ 'key' => nil })
    end
  end
end
