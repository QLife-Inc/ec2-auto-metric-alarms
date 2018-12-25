require 'spec_helper'

describe Settings do
  describe 'definition_bucket_name' do
    before { ENV['DEFINITION_BUCKET_NAME'] = 'test_bucket' }

    subject { described_class.definition_bucket_name }

    it { is_expected.to eq 'test_bucket' }
  end

  describe 'definition_object_prefix' do
    let(:prefix) { 'hoge/' }

    before do
      described_class.instance_variable_set(:@definition_object_prefix, nil)
      ENV['DEFINITION_OBJECT_PREFIX'] = prefix
    end

    subject { described_class.definition_object_prefix }

    context '末尾スラッシュがある場合' do
      let(:prefix) { 'hoge/' }

      it { is_expected.to eq 'hoge/' }
    end

    context '末尾スラッシュがない場合' do
      let(:prefix) { 'hoge' }

      it { is_expected.to eq 'hoge/' }
    end
  end

  describe 'definition_tag_key' do
    before do
      described_class.instance_variable_set(:@definition_tag_key, nil)
      ENV['DEFINITION_TAG_KEY'] = 'hogehoge'
    end

    subject { described_class.definition_tag_key }

    it { is_expected.to eq 'hogehoge' }
  end

  describe 'emergency_topic_arn' do
    before do
      described_class.instance_variable_set(:@emergency_topic_arn, nil)
      ENV['EMERGENCY_TOPIC_ARN'] = 'emergency'
    end

    subject { described_class.emergency_topic_arn }

    it { is_expected.to eq 'emergency' }
  end

  describe 'ordinary_topic_arn' do
    before do
      described_class.instance_variable_set(:@ordinary_topic_arn, nil)
      ENV['ORDINARY_TOPIC_ARN'] = 'ordinary'
    end

    subject { described_class.ordinary_topic_arn }

    it { is_expected.to eq 'ordinary' }
  end

  describe 'logger' do
    let(:log_level) { 'debug' }

    before do
      described_class.instance_variable_set(:@log_level, nil)
      described_class.instance_variable_set(:@logger, nil)
      ENV['LOG_LEVEL'] = log_level
    end

    subject { described_class.logger.level }

    it { is_expected.to eq Logger::Severity::DEBUG }

    context 'when log_level is not specified' do
      let(:log_level) { nil }

      it { is_expected.to eq Logger::Severity::INFO }
    end
  end

end
