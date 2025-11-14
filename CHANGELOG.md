# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2025-11-13

### Added
- Initial release of toon_my_json gem
- `ToonMyJson.encode` - Convert JSON/Ruby objects to TOON format
- `ToonMyJson.decode` - Convert TOON format back to JSON/Ruby objects
- Bidirectional conversion support (JSON ↔ TOON)
- Tabular format for uniform arrays (30-60% space savings)
- Smart string quoting (only when necessary)
- Support for nested structures (objects and arrays)
- Lossless roundtrip conversions
- Command-line interface (`toon` command)
  - `--encode` flag for JSON to TOON conversion (default)
  - `--decode` flag for TOON to JSON conversion
  - `--indent` option for custom indentation
  - `--delimiter` option for custom field delimiters
  - `--no-length-marker` option to disable array length markers

### Features
- Automatic detection of uniform arrays for tabular formatting
- Handles primitives, objects, arrays, and nested structures
- Multiple input types: JSON strings, Ruby objects, TOON strings
- Customizable encoding options (indent, delimiter, length markers)
- Ruby API and CLI support

[0.1.0]: https://github.com/mykyta/toon-my-json/releases/tag/v0.1.0
