# frozen_string_literal: true

require 'simplecov'

SimpleCov.start do
  add_filter '/spec/'
  enable_coverage :branch
  minimum_coverage line: 100, branch: 100 # We can do that hehe
end

require_relative '../lib/toon_my_json'

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = 'spec/.rspec_status'
  config.disable_monkey_patching!
  config.warnings = true

  # Exclude benchmark specs by default
  # Run with: bundle exec rspec --tag benchmark
  config.filter_run_excluding :benchmark unless ENV['BENCHMARK']

  config.default_formatter = 'doc' if config.files_to_run.one?

  config.profile_examples = 10
  config.order = :random
  Kernel.srand config.seed
end
