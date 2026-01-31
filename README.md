# ToonMyJson

A Ruby gem for bidirectional conversion between JSON and TOON (Token-Oriented Object Notation) format. TOON is a compact serialization format designed for Large Language Models that reduces token usage by 30-60% compared to JSON.

## What is TOON?

TOON is a compact, human-readable format that combines the best of YAML's indentation-based structure with CSV's tabular format for arrays. It minimizes syntax overhead by removing redundant punctuation like braces, brackets, and unnecessary quotes.

### Format Comparison

**JSON (verbose):**
```json
{
  "users": [
    { "id": 1, "name": "Alice", "role": "admin" },
    { "id": 2, "name": "Bob", "role": "user" }
  ]
}
```

**TOON (compact):**
```
users:
[2]{id,name,role}:
  1,Alice,admin
  2,Bob,user
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'toon_my_json'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install toon_my_json
```

## Requirements

- Ruby >= 3.0.0
- JSON gem (~> 2.0)

## Quick Start

```ruby
require 'toon_my_json'

# Encode JSON to TOON
data = { "users" => [{ "id" => 1, "name" => "Alice" }] }
toon = ToonMyJson.encode(data)
# => "users:\n[1]{id,name}:\n  1,Alice"

# Decode TOON back to JSON
restored = ToonMyJson.decode(toon)
# => {"users"=>[{"id"=>1, "name"=>"Alice"}]}
```

## Usage

### Ruby API

#### Encoding (JSON → TOON)

```ruby
require 'toon_my_json'

# Convert a Ruby hash to TOON
data = { "name" => "Alice", "age" => 30 }
ToonMyJson.encode(data)
# => "name: Alice\nage: 30"

# Convert a JSON string to TOON
json = '{"name":"Alice","age":30}'
ToonMyJson.encode(json)
# => "name: Alice\nage: 30"

# Arrays automatically use tabular format for uniform data
data = [
  { "id" => 1, "name" => "Alice", "role" => "admin" },
  { "id" => 2, "name" => "Bob", "role" => "user" }
]
ToonMyJson.encode(data)
# => "[2]{id,name,role}:\n1,Alice,admin\n2,Bob,user"
```

#### Decoding (TOON → JSON)

```ruby
# Convert TOON back to Ruby objects
toon = "name: Alice\nage: 30"
ToonMyJson.decode(toon)
# => {"name"=>"Alice", "age"=>30}

# Get JSON string output instead of Ruby object
ToonMyJson.decode(toon, json: true)
# => "{\n  \"name\": \"Alice\",\n  \"age\": 30\n}"
```

#### Roundtrip Conversion

```ruby
# Perfect lossless conversion
original = { "company" => "TechCorp", "year" => 2020 }
toon = ToonMyJson.encode(original)
restored = ToonMyJson.decode(toon)
# => {"company"=>"TechCorp", "year"=>2020}
original == restored  # => true
```

### Configuration Options

#### Encoding Options

```ruby
# Custom indentation (default: 2)
ToonMyJson.encode(data, indent: 4)

# Custom delimiter for arrays (default: ',')
ToonMyJson.encode(data, delimiter: '|')

# Disable length markers (default: true)
ToonMyJson.encode(data, length_marker: false)
```

### Decoding Options

```ruby
# Custom indentation for JSON output (default: 2)
ToonMyJson.decode(toon, indent: 4)

# Custom delimiter (must match what was used in encoding)
ToonMyJson.decode(toon, delimiter: '|')

# Get JSON string output instead of Ruby object
ToonMyJson.decode(toon, json: true)
```

### Command Line Interface

The gem includes a `toon` CLI tool for converting between JSON and TOON formats:

```bash
# Encode JSON to TOON (default)
$ toon input.json
$ echo '{"name":"Alice","age":30}' | toon

# Decode TOON to JSON
$ toon --decode input.toon
$ echo -e 'name: Alice\nage: 30' | toon --decode

# Roundtrip conversion
$ echo '{"name":"Alice"}' | toon | toon --decode

# Options
$ toon --indent 4 --delimiter '|' input.json      # Custom formatting
$ toon --no-length-marker input.json              # Disable array length markers
$ toon --decode --delimiter '|' input.toon        # Decode with custom delimiter

# Help and version
$ toon --help
$ toon --version
```

## Features

- **Bidirectional Conversion**: Encode JSON to TOON and decode TOON back to JSON
- **Tabular Format**: Automatically detects uniform arrays of objects and converts them to compact tabular format
- **Smart Quoting**: Only adds quotes when necessary (special characters, reserved words, etc.)
- **Nested Structures**: Handles deeply nested objects and arrays
- **Lossless Roundtrips**: Encode and decode without data loss
- **Flexible Options**: Customize indentation, delimiters, and length markers
- **CLI Tool**: Convert files from the command line with full encode/decode support
- **Multiple Input Types**: Accepts JSON strings, Ruby objects, or TOON strings

## Advanced Examples

### Complex Nested Structure

```ruby
data = {
  "company" => "TechCorp",
  "employees" => [
    { "id" => 1, "name" => "Alice", "department" => "Engineering" },
    { "id" => 2, "name" => "Bob", "department" => "Sales" }
  ],
  "metadata" => {
    "founded" => 2020,
    "location" => "San Francisco"
  }
}

puts ToonMyJson.encode(data)
```

**Output:**
```
company: TechCorp
employees:
[2]{id,name,department}:
  1,Alice,Engineering
  2,Bob,Sales
metadata:
  founded: 2020
  location: San Francisco
```

### Primitive Arrays

```ruby
data = { "colors" => ["red", "green", "blue"] }
ToonMyJson.encode(data)
# => "colors: red,green,blue"
```

### Mixed Arrays

```ruby
data = ["string", 42, { "key" => "value" }]
ToonMyJson.encode(data)
# => "- string\n- 42\n- key: value"
```

### Decoding Examples

```ruby
# Decode simple hash
toon = <<~TOON
  name: Alice
  age: 30
TOON
ToonMyJson.decode(toon)
# => {"name"=>"Alice", "age"=>30}

# Decode tabular array
toon = <<~TOON
  [2]{id,name,role}:
    1,Alice,admin
    2,Bob,user
TOON
ToonMyJson.decode(toon)
# => [{"id"=>1, "name"=>"Alice", "role"=>"admin"}, {"id"=>2, "name"=>"Bob", "role"=>"user"}]

# Decode complex nested structure
toon = <<~TOON
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
# => {"company"=>"TechCorp", "employees"=>[...], "metadata"=>{...}}
```

## Development

After checking out the repo, run `bundle install` to install dependencies:

```bash
bundle install
```

Run the test suite:

```bash
bundle exec rspec
# or
bundle exec rake spec
```

This represents complete test coverage for production Ruby code, ensuring all code paths and conditional branches are thoroughly tested.

Run performance benchmarks (performance can be improved):

```bash
# Run all benchmark tests
bundle exec rspec --tag benchmark

# Or with environment variable
BENCHMARK=1 bundle exec rspec

# Run only the benchmark-ips comparison (shows iterations/second)
bundle exec rspec --tag ips
```

Performance benchmarks validate:
- Encoding 1000 records completes in under 10ms
- Decoding 1000 records completes in under 50ms
- Roundtrip conversion completes in under 60ms
- Iterations per second for common operations

Install the gem locally:

```bash
bundle exec rake install
```

Build the gem:

```bash
bundle exec rake build
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/mykbren/toon-my-json.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Sponsor

Development of this gem is sponsored by [tseivo.com](https://tseivo.com)

## References

- [TOON Format Specification](https://github.com/toon-format/toon)
- [Original TypeScript Implementation](https://github.com/toon-format/toon)
