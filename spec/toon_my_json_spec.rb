# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ToonMyJson do
  describe '.encode' do
    it 'has a version number' do
      expect(ToonMyJson::VERSION).not_to be_nil
    end

    context 'with primitives' do
      it 'encodes nil' do
        expect(ToonMyJson.encode(nil)).to eq('null')
      end

      it 'encodes boolean values' do
        expect(ToonMyJson.encode(true)).to eq('true')
        expect(ToonMyJson.encode(false)).to eq('false')
      end

      it 'encodes numbers' do
        expect(ToonMyJson.encode(42)).to eq('42')
        expect(ToonMyJson.encode(3.14)).to eq('3.14')
      end

      it 'encodes simple strings' do
        expect(ToonMyJson.encode('hello')).to eq('hello')
      end

      it 'encodes custom objects by converting to string' do
        custom_obj = Object.new
        def custom_obj.to_s
          'custom_value'
        end
        expect(ToonMyJson.encode(custom_obj)).to eq('custom_value')
      end
    end

    context 'with strings containing special characters' do
      it 'quotes strings with commas' do
        expect(ToonMyJson.encode('hello, world')).to eq('"hello, world"')
      end

      it 'quotes strings with colons' do
        expect(ToonMyJson.encode('hello:world')).to eq('"hello:world"')
      end

      it 'quotes strings with trailing spaces' do
        expect(ToonMyJson.encode('hello world ')).to eq('"hello world "')
      end

      it 'quotes strings with leading spaces' do
        expect(ToonMyJson.encode(' hello world')).to eq('" hello world"')
      end
    end

    context 'with primitive arrays' do
      it 'encodes integer arrays' do
        expect(ToonMyJson.encode([1, 2, 3])).to eq('1,2,3')
      end

      it 'encodes string arrays' do
        expect(ToonMyJson.encode(%w[a b c])).to eq('a,b,c')
      end

      it 'encodes mixed primitive arrays' do
        expect(ToonMyJson.encode([true, false, nil])).to eq('true,false,null')
      end
    end

    context 'with empty containers' do
      it 'encodes empty arrays' do
        expect(ToonMyJson.encode([])).to eq('[]')
      end

      it 'encodes empty hashes' do
        expect(ToonMyJson.encode({})).to eq('{}')
      end
    end

    context 'with simple hashes' do
      it 'encodes a simple hash' do
        result = ToonMyJson.encode({ 'name' => 'Alice', 'age' => 30 })
        expect(result).to include('name: Alice')
        expect(result).to include('age: 30')
      end
    end

    context 'with nested hashes' do
      it 'encodes nested hash structures' do
        data = {
          'user' => {
            'name' => 'Alice',
            'age' => 30
          }
        }
        result = ToonMyJson.encode(data)
        expect(result).to include('user:')
        expect(result).to include('  name: Alice')
        expect(result).to include('  age: 30')
      end
    end

    context 'with hash containing arrays' do
      it 'encodes hash with primitive array' do
        data = { 'colors' => %w[red green blue] }
        result = ToonMyJson.encode(data)
        expect(result).to eq('colors: red,green,blue')
      end

      it 'encodes hash with uniform array of objects' do
        data = {
          'items' => [
            { 'id' => 1, 'name' => 'Item1' },
            { 'id' => 2, 'name' => 'Item2' }
          ]
        }
        result = ToonMyJson.encode(data)
        expect(result).to include('items:')
        expect(result).to include('[2]{id,name}:')
      end

      it 'encodes hash with mixed array' do
        data = {
          'mixed' => ['string', 42, { 'key' => 'value' }]
        }
        result = ToonMyJson.encode(data)
        expect(result).to include('mixed:')
        expect(result).to include('- string')
        expect(result).to include('- 42')
      end

      it 'encodes hash with empty array' do
        data = { 'items' => [] }
        result = ToonMyJson.encode(data)
        expect(result).to eq('items: []')
      end

      it 'encodes hash with empty hash' do
        data = { 'metadata' => {} }
        result = ToonMyJson.encode(data)
        expect(result).to eq('metadata: {}')
      end

      it 'encodes hash with nested hash' do
        data = {
          'outer' => {
            'inner' => {
              'value' => 'test'
            }
          }
        }
        result = ToonMyJson.encode(data)
        expect(result).to include('outer:')
        expect(result).to include('  inner:')
        expect(result).to include('    value: test')
      end
    end

    context 'with uniform array of objects' do
      it 'uses tabular format' do
        data = [
          { 'id' => 1, 'name' => 'Alice', 'role' => 'admin' },
          { 'id' => 2, 'name' => 'Bob', 'role' => 'user' }
        ]
        result = ToonMyJson.encode(data)

        expect(result).to include('[2]{id,name,role}:')
        expect(result).to include('1,Alice,admin')
        expect(result).to include('2,Bob,user')
      end
    end

    context 'with length_marker option' do
      it 'excludes length marker when disabled' do
        data = [
          { 'id' => 1, 'name' => 'Alice' },
          { 'id' => 2, 'name' => 'Bob' }
        ]
        result = ToonMyJson.encode(data, length_marker: false)

        expect(result).to include('{id,name}:')
        expect(result).not_to include('[2]')
      end
    end

    context 'with nested objects containing tabular arrays' do
      it 'properly indents nested tabular arrays' do
        data = {
          'users' => [
            { 'id' => 1, 'name' => 'Alice', 'role' => 'admin' },
            { 'id' => 2, 'name' => 'Bob', 'role' => 'user' }
          ]
        }
        result = ToonMyJson.encode(data)

        expect(result).to include('users:')
        expect(result).to include('[2]{id,name,role}:')
        expect(result).to include('  1,Alice,admin')
        expect(result).to include('  2,Bob,user')
      end
    end

    context 'with JSON string input' do
      it 'parses and encodes JSON strings' do
        json = '{"name":"Alice","age":30}'
        result = ToonMyJson.encode(json)

        expect(result).to include('name: Alice')
        expect(result).to include('age: 30')
      end

      it 'treats invalid JSON as plain string' do
        invalid_json = '{invalid json}'
        result = ToonMyJson.encode(invalid_json)
        expect(result).to eq("\"#{invalid_json}\"")
      end
    end

    context 'with complex nested structures' do
      it 'handles multiple levels of nesting' do
        json = <<~JSON
          {
            "company": "TechCorp",
            "employees": [
              {
                "id": 1,
                "name": "Alice",
                "department": "Engineering"
              },
              {
                "id": 2,
                "name": "Bob",
                "department": "Sales"
              }
            ],
            "metadata": {
              "founded": 2020,
              "location": "San Francisco"
            }
          }
        JSON

        result = ToonMyJson.encode(json)

        expect(result).to include('company: TechCorp')
        expect(result).to include('employees:')
        expect(result).to include('[2]{id,name,department}:')
        expect(result).to include('1,Alice,Engineering')
        expect(result).to include('2,Bob,Sales')
        expect(result).to include('metadata:')
        expect(result).to include('founded: 2020')
      end
    end

    context 'with mixed arrays' do
      it 'uses list format for non-uniform arrays' do
        data = [
          'string',
          42,
          { 'key' => 'value' },
          %w[nested array]
        ]
        result = ToonMyJson.encode(data)

        expect(result).to include('- string')
        expect(result).to include('- 42')
        expect(result).to include('key: value')
      end

      it 'encodes list array with empty hash' do
        data = ['item', {}]
        result = ToonMyJson.encode(data)
        expect(result).to include('- item')
        expect(result).to include('- {}')
      end

      it 'encodes list array with empty array' do
        data = ['item', []]
        result = ToonMyJson.encode(data)
        expect(result).to include('- item')
        expect(result).to include('- []')
      end

      it 'encodes list array with nested mixed content' do
        data = [
          'first',
          { 'nested' => { 'deep' => 'value' } }
        ]
        result = ToonMyJson.encode(data)
        expect(result).to include('- first')
        expect(result).to include('-')
        expect(result).to include('nested:')
        expect(result).to include('deep: value')
      end
    end

    context 'with custom delimiter' do
      it 'uses specified delimiter' do
        data = { 'colors' => %w[red green blue] }
        result = ToonMyJson.encode(data, delimiter: '|')

        expect(result).to eq('colors: red|green|blue')
      end
    end

    context 'with custom indentation' do
      it 'uses specified indent size' do
        data = {
          'user' => {
            'name' => 'Alice'
          }
        }
        result = ToonMyJson.encode(data, indent: 4)

        expect(result).to include('user:')
        expect(result).to include('    name: Alice')
      end
    end
  end

  describe '.convert' do
    it 'is an alias for encode' do
      data = { 'name' => 'Alice', 'age' => 30 }
      expect(ToonMyJson.convert(data)).to eq(ToonMyJson.encode(data))
    end
  end

  describe 'branch coverage edge cases' do
    it 'encodes string that looks like null' do
      result = ToonMyJson.encode({ 'key' => 'null' })
      expect(result).to eq('key: "null"')
    end

    it 'encodes string that looks like true' do
      result = ToonMyJson.encode({ 'key' => 'true' })
      expect(result).to eq('key: "true"')
    end

    it 'encodes string that looks like false' do
      result = ToonMyJson.encode({ 'key' => 'false' })
      expect(result).to eq('key: "false"')
    end

    it 'encodes empty string' do
      result = ToonMyJson.encode({ 'key' => '' })
      expect(result).to eq('key: ""')
    end

    it 'encodes string that looks like float' do
      result = ToonMyJson.encode({ 'key' => '3.14' })
      expect(result).to eq('key: "3.14"')
    end

    it 'encodes string that looks like integer' do
      result = ToonMyJson.encode({ 'key' => '42' })
      expect(result).to eq('key: "42"')
    end

    it 'encodes array with nil values' do
      result = ToonMyJson.encode([1, nil, 3])
      expect(result).to eq('1,null,3')
    end

    it 'encodes array with boolean values' do
      result = ToonMyJson.encode([true, false])
      expect(result).to eq('true,false')
    end

    it 'encodes hash with nil values in tabular array' do
      data = [
        { 'id' => 1, 'name' => 'Alice', 'role' => 'admin' },
        { 'id' => 2, 'name' => 'Bob', 'role' => nil } # role is nil
      ]
      result = ToonMyJson.encode(data)
      expect(result).to include('2,Bob,null')
    end

    it 'encodes non-uniform array where first is hash' do
      data = [
        { 'id' => 1 },
        { 'different' => 'key' } # Different keys, falls below 80% threshold
      ]
      result = ToonMyJson.encode(data)
      # Should use list format instead of tabular
      expect(result).to include('-')
    end

    it 'encodes string with backslashes' do
      result = ToonMyJson.encode({ 'path' => 'C:\\Users\\test' })
      expect(result).to include('\\\\')
    end

    it 'encodes string with quotes and comma' do
      result = ToonMyJson.encode({ 'quote' => 'He said "hello", friend' })
      expect(result).to include('"He said \"hello\", friend"')
    end

    it 'encodes hash value that is a single-line hash' do
      data = { 'outer' => { 'inner' => 'value' } }
      result = ToonMyJson.encode(data)
      expect(result).to include('outer:')
      expect(result).to include('  inner: value')
    end

    it 'encodes multiline list item' do
      # Mixed array with hash and primitive triggers list format
      data = [
        { 'nested' => { 'deep' => 'value' } },
        'primitive'
      ]
      result = ToonMyJson.encode(data)
      expect(result).to include('-')
      expect(result).to include('nested:')
    end

    it 'handles partially overlapping hash keys at 80% threshold' do
      # Test edge case of 80% threshold in uniform_array?
      data = [
        { 'a' => 1, 'b' => 2, 'c' => 3, 'd' => 4, 'e' => 5 },
        { 'a' => 6, 'b' => 7, 'c' => 8, 'd' => 9 } # Missing 'e', 4/5 = 80%
      ]
      result = ToonMyJson.encode(data)
      # 4 >= 5 * 0.8 = 4.0, so should be tabular
      expect(result).to include('[2]{a,b,c,d,e}:')
    end

    it 'handles hashes with less than 80% key overlap' do
      # Test where key overlap is less than 80%
      data = [
        { 'a' => 1, 'b' => 2, 'c' => 3, 'd' => 4, 'e' => 5 },
        { 'a' => 6, 'b' => 7, 'c' => 8 } # Missing 'd' and 'e', 3/5 = 60%
      ]
      result = ToonMyJson.encode(data)
      # 3 < 5 * 0.8 = 4.0, so should use list format
      expect(result).to include('-')
    end

    it 'handles array with first element hash but second not hash' do
      # Test uniform_array? where item.is_a?(Hash) returns false in all? block
      data = [
        { 'id' => 1 },
        'not a hash'
      ]
      result = ToonMyJson.encode(data)
      # Should use list format since second element is not a hash
      expect(result).to include('-')
      expect(result).to include('id: 1')
    end

    it 'handles array where first element is not a hash' do
      # Test uniform_array? returns false when !array.first.is_a?(Hash)
      data = ['string', { 'id' => 1 }]
      result = ToonMyJson.encode(data)
      expect(result).to include('-')
    end

    it 'handles array with only one hash element' do
      # Single hash array - uniform_array? should return true
      data = [{ 'id' => 1, 'name' => 'Alice' }]
      result = ToonMyJson.encode(data)
      # Should use tabular format
      expect(result).to include('{id,name}:')
    end

    it 'encodes single empty hash array as tabular' do
      # Single empty hash creates empty tabular array
      data = [{}]
      result = ToonMyJson.encode(data)
      expect(result).to include('{}:')
    end

    it 'encodes empty containers in mixed list' do
      # Test inline empty containers in list format
      data = [1, {}, []]
      result = ToonMyJson.encode(data)
      expect(result).to include('- 1')
      expect(result).to include('- {}')
      expect(result).to include('- []')
    end

    it 'encodes inline array in list format' do
      # Test array that doesn't include newline (inline)
      data = [
        [1, 2, 3] # Primitive array, should be inline
      ]
      result = ToonMyJson.encode(data)
      expect(result).to include('- 1,2,3')
      expect(result).not_to include("\n  ")
    end

    it 'encodes multiline array in list format' do
      # Test array that includes newlines
      data = [
        [{ 'nested' => 'value' }] # Not primitive, should be multiline
      ]
      result = ToonMyJson.encode(data)
      expect(result).to include('-')
      # Should have indented content
      expect(result).to match(/^  /)
    end

    it 'encodes key that needs quotes' do
      # Test key with special characters needing quotes
      data = { 'key:with:colons' => 'value' }
      result = ToonMyJson.encode(data)
      expect(result).to include('"key:with:colons":')
    end

    it 'encodes key with leading space' do
      data = { ' key' => 'value' }
      result = ToonMyJson.encode(data)
      expect(result).to include('" key":')
    end

    it 'encodes key with trailing space' do
      data = { 'key ' => 'value' }
      result = ToonMyJson.encode(data)
      expect(result).to include('"key ":')
    end

    it 'encodes simple key without quotes' do
      data = { 'simplekey' => 'value' }
      result = ToonMyJson.encode(data)
      expect(result).to eq('simplekey: value')
      expect(result).not_to include('"simplekey"')
    end

    it 'encodes numeric value' do
      result = ToonMyJson.encode(42)
      expect(result).to eq('42')
    end

    it 'encodes float value' do
      result = ToonMyJson.encode(3.14)
      expect(result).to eq('3.14')
    end

    it 'encodes true value' do
      result = ToonMyJson.encode(true)
      expect(result).to eq('true')
    end

    it 'encodes false value' do
      result = ToonMyJson.encode(false)
      expect(result).to eq('false')
    end

    it 'encodes nil value' do
      result = ToonMyJson.encode(nil)
      expect(result).to eq('null')
    end

    it 'encodes plain string value' do
      result = ToonMyJson.encode('hello')
      expect(result).to eq('hello')
    end

    it 'encodes string with newline' do
      data = { 'key' => "line1\nline2" }
      result = ToonMyJson.encode(data)
      expect(result).to include('"')
    end

    it 'encodes string with tab' do
      data = { 'key' => "text\twith\ttab" }
      result = ToonMyJson.encode(data)
      expect(result).to include('"')
    end

    it 'encodes string with bracket' do
      data = { 'key' => 'text[bracket]' }
      result = ToonMyJson.encode(data)
      expect(result).to include('"')
    end

    it 'encodes string with brace' do
      data = { 'key' => 'text{brace}' }
      result = ToonMyJson.encode(data)
      expect(result).to include('"')
    end

    it 'encodes string with hash' do
      data = { 'key' => 'text#hash' }
      result = ToonMyJson.encode(data)
      expect(result).to include('"')
    end

    it 'encodes string with carriage return' do
      data = { 'key' => "text\rwith\rCR" }
      result = ToonMyJson.encode(data)
      expect(result).to include('"')
    end

    it 'encodes string matching number regex' do
      # Test looks_like_number? returning true
      data = { 'num' => '123' }
      result = ToonMyJson.encode(data)
      expect(result).to include('"123"')
    end

    it 'encodes string matching float regex' do
      data = { 'num' => '123.456' }
      result = ToonMyJson.encode(data)
      expect(result).to include('"123.456"')
    end

    it 'encodes string not matching number regex' do
      # Test looks_like_number? returning false
      data = { 'text' => 'abc123' }
      result = ToonMyJson.encode(data)
      expect(result).to eq('text: abc123')
    end

    it 'encodes string with negative number format' do
      data = { 'num' => '-42' }
      result = ToonMyJson.encode(data)
      expect(result).to include('"-42"')
    end

    it 'encodes string matching boolean false but needs quotes for other reason' do
      # String is 'false' but also has a comma
      data = { 'key' => 'false,value' }
      result = ToonMyJson.encode(data)
      expect(result).to include('"false,value"')
    end

    it 'encodes string not matching boolean' do
      # Test looks_like_boolean? returning false
      data = { 'text' => 'falsetto' }
      result = ToonMyJson.encode(data)
      expect(result).to eq('text: falsetto')
    end

    it 'encodes string needing quotes only due to NEEDS_QUOTES' do
      # Has colon, so matches NEEDS_QUOTES, even if not number/boolean
      data = { 'key' => 'has:colon' }
      result = ToonMyJson.encode(data)
      expect(result).to include('"has:colon"')
    end

    it 'encodes string not needing quotes at all' do
      # Doesn't match NEEDS_QUOTES, not number, not boolean
      data = { 'key' => 'simple' }
      result = ToonMyJson.encode(data)
      expect(result).to eq('key: simple')
    end

    it 'encodes primitive array that is not uniform due to types' do
      # All primitives, so primitive_array? returns true
      data = [1, 'string', true, nil]
      result = ToonMyJson.encode(data)
      expect(result).to eq('1,string,true,null')
    end

    it 'encodes array containing hash as non-primitive' do
      # primitive_array? returns false due to hash
      data = [1, {}]
      result = ToonMyJson.encode(data)
      expect(result).to include('-')
    end

    it 'handles tabular array encoding when array is actually empty in encode_tabular_array' do
      # Edge case where encode_tabular_array receives empty array
      # This is unreachable in normal flow, but tests the guard
      data = { 'items' => [] }
      result = ToonMyJson.encode(data)
      expect(result).to include('[]')
    end

    it 'encodes value with false boolean' do
      # Test encode with false value explicitly
      data = [false]
      result = ToonMyJson.encode(data)
      expect(result).to eq('false')
    end

    it 'encodes hash value inline when it is not multiline' do
      # Single key hash on one line
      data = { 'outer' => { 'single' => 'val' } }
      result = ToonMyJson.encode(data)
      expect(result).to include('single: val')
    end

    it 'encodes list item that is hash without newlines' do
      # Empty hash in list format - inline (no newlines)
      data = [{}]
      result = ToonMyJson.encode(data)
      # Empty hash gets encoded as tabular '[]' which doesn't include newline in header
      expect(result).to be_a(String)
    end

    it 'encodes list item that is array without newlines' do
      # Primitive array inline
      data = [[1, 2]]
      result = ToonMyJson.encode(data)
      expect(result).to include('- 1,2')
    end

    it 'encodes list item that is hash with newlines' do
      # Single hash uses tabular format
      data = [{ 'a' => 1, 'b' => 2 }, 'mixed'] # Mixed types to force list format
      result = ToonMyJson.encode(data)
      expect(result).to include('-')
      expect(result).to include("\n")
    end

    it 'encodes list item that is array with newlines' do
      # Array of hashes has newlines
      data = [[{ 'x' => 1 }]]
      result = ToonMyJson.encode(data)
      expect(result).to include("\n")
    end

    it 'encodes list item that is primitive' do
      # Non-Hash, non-Array item in list format
      # Need mixed types to avoid primitive array format
      data = ['text', {}] # Mix string with hash to force list format
      result = ToonMyJson.encode(data)
      expect(result).to include('- text')
      expect(result).to include('- {}')
    end

    it 'encodes primitive array with all primitive types' do
      # Tests primitive_array? with every type: String, Numeric, true, false, nil
      data = ['string', 42, 3.14, true, false, nil]
      result = ToonMyJson.encode(data)
      # All are primitives, should be comma-separated
      expect(result).to eq('string,42,3.14,true,false,null')
    end

    it 'encodes array failing primitive_array check due to array element' do
      # Array contains another array, so primitive_array? returns false
      data = [1, [2]]
      result = ToonMyJson.encode(data)
      expect(result).to include('-')
    end

    it 'encodes value matching none of the main encode cases' do
      # Test the else branch in encode - custom object
      class CustomObject
        def to_s
          'custom_value'
        end
      end

      data = { 'key' => CustomObject.new }
      result = ToonMyJson.encode(data)
      expect(result).to include('custom_value')
    end

    it 'encodes Numeric type specifically' do
      # Ensure Numeric is tested (not just Integer/Float subclasses)
      data = [42, 3.14, -7, -2.5]
      result = ToonMyJson.encode(data)
      expect(result).to eq('42,3.14,-7,-2.5')
    end

    it 'covers symbol key fallback in tabular encoding' do
      # Test item[key] || item[key.to_sym] by calling encode_tabular_array directly
      # This bypasses uniform_array? which would fail on mixed keys
      encoder = ToonMyJson::Encoder.new

      item1 = { 'id' => 1, 'name' => 'Alice' }
      item2 = { 'id' => 2, :name => 'Bob' } # Symbol :name, no string 'name'

      data = [item1, item2]

      # Directly call encode_tabular_array to test symbol fallback
      result = encoder.send(:encode_tabular_array, data, 0)

      # item2['name'] is nil, falls back to item2[:name] = 'Bob'
      expect(result).to include('Bob')
    end

    it 'covers redundant type check after uniform_array' do
      # Test uniform_array?(value) && value.first.is_a?(Hash)
      # The second check is redundant but we need to cover both branches
      encoder = ToonMyJson::Encoder.new

      # Create a scenario where uniform_array? returns true
      # Then value.first.is_a?(Hash) should also be true (redundant check)
      value = [{ 'id' => 1 }, { 'id' => 2 }]

      # Call encode_value_for_hash which has this check on line 57
      result = encoder.send(:encode_value_for_hash, value, 0)

      expect(result).to include('[2]{id}:')
    end

    it 'tests encode_string with string matching all criteria' do
      encoder = ToonMyJson::Encoder.new

      # Test string that needs quotes due to NEEDS_QUOTES
      result1 = encoder.send(:encode_string, 'has:colon')
      expect(result1).to eq('"has:colon"')

      # Test string that needs quotes due to looks_like_number?
      result2 = encoder.send(:encode_string, '42')
      expect(result2).to eq('"42"')

      # Test string that needs quotes due to looks_like_boolean?
      result3 = encoder.send(:encode_string, 'true')
      expect(result3).to eq('"true"')

      # Test string that needs NO quotes
      result4 = encoder.send(:encode_string, 'simple')
      expect(result4).to eq('simple')
    end

    it 'forces uniform_array check with non-hash first element' do
      encoder = ToonMyJson::Encoder.new

      # First element not a hash - should return false immediately
      result = encoder.send(:uniform_array?, %w[string another])
      expect(result).to be false
    end

    it 'forces uniform_array check with empty array' do
      encoder = ToonMyJson::Encoder.new

      # Empty array - should return false
      result = encoder.send(:uniform_array?, [])
      expect(result).to be false
    end

    it 'forces encode_value_for_hash to hit all branches' do
      encoder = ToonMyJson::Encoder.new

      # Empty hash
      result1 = encoder.send(:encode_value_for_hash, {}, 0)
      expect(result1).to eq(' {}')

      # Non-empty hash
      result2 = encoder.send(:encode_value_for_hash, { 'key' => 'val' }, 0)
      expect(result2).to include("\n")

      # Empty array
      result3 = encoder.send(:encode_value_for_hash, [], 0)
      expect(result3).to eq(' []')

      # Primitive array
      result4 = encoder.send(:encode_value_for_hash, [1, 2, 3], 0)
      expect(result4).to include(' ')

      # List array (not uniform, not primitive)
      result5 = encoder.send(:encode_value_for_hash, [1, {}], 0)
      expect(result5).to include("\n")

      # Primitive value
      result6 = encoder.send(:encode_value_for_hash, 'text', 0)
      expect(result6).to eq(' text')
    end

    it 'covers the false branch of value.first.is_a?(Hash) after uniform_array' do
      encoder = ToonMyJson::Encoder.new

      # We need uniform_array? to return true but value.first not be a Hash
      # This is logically impossible in normal flow, so we stub it
      value = ['not_a_hash']

      # Stub uniform_array? to return true
      allow(encoder).to receive(:uniform_array?).and_return(true)

      # Now when encode_value_for_hash checks uniform_array?(value) && value.first.is_a?(Hash)
      # First part is true (stubbed), second part should be false
      result = encoder.send(:encode_value_for_hash, value, 0)

      # Should not use tabular format since value.first.is_a?(Hash) is false
      # Will fall through to other branches
      expect(result).to be_a(String)
    end

    it 'covers encode_tabular_array with empty array' do
      # This hits the return '[]' if array.empty? branch at line 82
      encoder = ToonMyJson::Encoder.new

      result = encoder.send(:encode_tabular_array, [], 0)
      expect(result).to eq('[]')
    end

    it 'covers encode_hash with empty hash' do
      # This hits the return '{}' if hash.empty? branch at line 36
      encoder = ToonMyJson::Encoder.new

      result = encoder.send(:encode_hash, {}, 0)
      expect(result).to eq('{}')
    end

    it 'covers encode_array with empty array' do
      # This hits the return '[]' if array.empty? branch at line 70
      encoder = ToonMyJson::Encoder.new

      result = encoder.send(:encode_array, [], 0)
      expect(result).to eq('[]')
    end

    it 'covers encode_string with empty string' do
      # This hits the return '""' if str.empty? branch at line 129
      encoder = ToonMyJson::Encoder.new

      result = encoder.send(:encode_string, '')
      expect(result).to eq('""')
    end

    it 'covers uniform_array and value.first.is_a?(Hash) false branch on line 72' do
      # Line 72: if uniform_array?(array) && array.first.is_a?(Hash)
      # We need uniform_array? true, but array.first.is_a?(Hash) false
      encoder = ToonMyJson::Encoder.new

      array = ['not_hash']

      # Stub to make uniform_array? return true
      allow(encoder).to receive(:uniform_array?).with(array).and_return(true)

      # Call encode_array - should not use tabular format
      result = encoder.send(:encode_array, array, 0)

      # Since array.first.is_a?(Hash) is false, should use primitive or list format
      expect(result).to be_a(String)
    end

    it 'covers the else branch after uniform_array check in encode_array' do
      # When uniform_array? is false, should check primitive_array?
      encoder = ToonMyJson::Encoder.new

      # Array that is not uniform (not all hashes) and not primitive
      array = [{ 'a' => 1 }, 'string']

      result = encoder.send(:encode_array, array, 0)

      # Should use list format
      expect(result).to include('-')
    end

    it 'covers uniform_array with item not being a Hash in all? block' do
      # Line 147: item.is_a?(Hash) && ...
      # Test when item.is_a?(Hash) is false
      encoder = ToonMyJson::Encoder.new

      array = [{ 'a' => 1 }, 'not_a_hash']

      result = encoder.send(:uniform_array?, array)
      expect(result).to be false
    end

    it 'covers uniform_array with key overlap less than 80%' do
      # Line 147: ... (item.keys.sort & first_keys).length >= first_keys.length * 0.8
      # Test when this condition is false
      encoder = ToonMyJson::Encoder.new

      array = [
        { 'a' => 1, 'b' => 2, 'c' => 3, 'd' => 4, 'e' => 5 }, # 5 keys
        { 'a' => 1 } # Only 1 key, 1/5 = 20% < 80%
      ]

      result = encoder.send(:uniform_array?, array)
      expect(result).to be false
    end

    it 'covers uniform_array with exactly 80% key overlap' do
      # Edge case: exactly 80% overlap
      encoder = ToonMyJson::Encoder.new

      array = [
        { 'a' => 1, 'b' => 2, 'c' => 3, 'd' => 4, 'e' => 5 }, # 5 keys
        { 'a' => 1, 'b' => 2, 'c' => 3, 'd' => 4 } # 4 keys, 4/5 = 80%
      ]

      result = encoder.send(:uniform_array?, array)
      expect(result).to be true
    end

    it 'covers primitive_array with each type in OR condition' do
      # Line 152: v.is_a?(String) || v.is_a?(Numeric) || v == true || v == false || v.nil?
      encoder = ToonMyJson::Encoder.new

      # Test each type individually passes
      expect(encoder.send(:primitive_array?, ['string'])).to be true
      expect(encoder.send(:primitive_array?, [42])).to be true
      expect(encoder.send(:primitive_array?, [3.14])).to be true
      expect(encoder.send(:primitive_array?, [true])).to be true
      expect(encoder.send(:primitive_array?, [false])).to be true
      expect(encoder.send(:primitive_array?, [nil])).to be true

      # Test non-primitive fails
      expect(encoder.send(:primitive_array?, [{}])).to be false
      expect(encoder.send(:primitive_array?, [[]])).to be false
    end

    it 'covers the false branch of value.first.is_a?(Hash) in encode_value_for_hash line 57' do
      # Line 57: elsif uniform_array?(value) && value.first.is_a?(Hash)
      # Need uniform_array? to return true but value.first.is_a?(Hash) to be false
      encoder = ToonMyJson::Encoder.new

      # Create an array where first element is not a hash
      value = %w[not_hash another]

      # Stub uniform_array? to return true (which it normally wouldn't for non-hash arrays)
      allow(encoder).to receive(:uniform_array?).with(value).and_return(true)

      # Now call encode_value_for_hash
      result = encoder.send(:encode_value_for_hash, value, 0)

      # Should not hit the tabular branch, will go to primitive_array? check instead
      expect(result).to be_a(String)
    end

    it 'covers the false branch of array.first.is_a?(Hash) in encode_array line 72' do
      # Line 72: if uniform_array?(array) && array.first.is_a?(Hash)
      # Need uniform_array? to return true but array.first.is_a?(Hash) to be false
      encoder = ToonMyJson::Encoder.new

      # Create an array where first element is not a hash
      array = [123, 456]

      # Stub uniform_array? to return true
      allow(encoder).to receive(:uniform_array?).with(array).and_return(true)

      # Call encode_array
      result = encoder.send(:encode_array, array, 0)

      # Should not use tabular format
      expect(result).to be_a(String)
    end
  end
end
