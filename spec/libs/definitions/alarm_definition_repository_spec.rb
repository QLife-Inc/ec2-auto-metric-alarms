require 'spec_helper'
require 'stringio'

describe AlarmDefinitionRepository do
  let(:bucket_name) { 'test_bucket' }
  let(:prefix) { 'definitions/' }
  let(:response) do
    {
      head_object: { content_length: 1 },
      get_object: { body: StringIO.new('hoge') }
    }
  end
  let(:client) { Aws::S3::Client.new(stub_responses: response) }
  let(:target) { described_class.new(client) }

  before do
    ENV['DEFINITION_BUCKET_NAME'] = bucket_name
    ENV['DEFINITION_OBJECT_PREFIX'] = prefix
  end

  describe 'initialize' do
    describe 'bucket' do
      subject { target.instance_variable_get(:@bucket).name }

      it { is_expected.to eq bucket_name }
    end

    describe 'prefix' do
      subject { target.instance_variable_get(:@prefix) }

      it { is_expected.to eq prefix }
    end
  end

  describe 'get_alarm_definition' do
    let(:definition_name) { 'test.json' }

    subject { target.get_alarm_definition(definition_name).body }

    it { is_expected.to eq 'hoge' }

    context 'when object is missing' do
      let(:response) { { head_object: nil } }

      it { is_expected.to eq '{"error":"s3://test_bucket/definitions/test.json is not found."}' }
    end
  end
end
