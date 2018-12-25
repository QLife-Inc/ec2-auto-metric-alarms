require 'simplecov'
require 'simplecov-console'

FORMATTERS = [
  SimpleCov::Formatter::HTMLFormatter,
  SimpleCov::Formatter::Console,
]

SimpleCov.start do
  add_filter '/vendor/'
  add_filter '/src/vendor/'
  add_filter '/spec/'
  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new(FORMATTERS)
end

require_relative '../src/libs/loader'

RSpec.configure do |config|
  config.before(:all) do
    ENV['DEFINITION_BUCKET_NAME'] = 'test_bucket'
    ENV['DEFINITION_OBJECT_PREFIX'] = 'definitions/'
    ENV['DEFINITION_TAG_KEY'] = 'AlarmDefinitionName'
    ENV['EMERGENCY_TOPIC_ARN'] = 'emergency-topic'
    ENV['ORDINARY_TOPIC_ARN'] = 'ordinary-topic'
    ENV['LOG_LEVEL'] = 'debug'
  end
  config.after(:all) do
    ENV['DEFINITION_BUCKET_NAME'] = nil
    ENV['DEFINITION_OBJECT_PREFIX'] = nil
    ENV['DEFINITION_TAG_KEY'] = nil
    ENV['EMERGENCY_TOPIC_ARN'] = nil
    ENV['ORDINARY_TOPIC_ARN'] = nil
    ENV['LOG_LEVEL'] = nil
  end
end
