require 'spec_helper'

describe AlarmResource do
  let(:prefix) { 'ec2-hoge' }
  let(:response) do
    {
      alarm_name: 'ec2-hoge-moge'
    }
  end
  let(:stub_responses) do
    { describe_alarms: { metric_alarms: [ response ] } }
  end
  let(:cloudwatch) { Aws::CloudWatch::Client.new(stub_responses: stub_responses) }
  let(:target) { described_class.new(cloudwatch) }

  describe 'alarm' do
    subject { target.alarm(AlarmDefinition.new({alarm_name: 'hoge'})) }
    it { is_expected.to be_instance_of Alarm }
  end

  describe 'find_by_name_prefix' do
    subject { target.find_by_name_prefix(prefix) }

    it do
      is_expected.to be_instance_of Aws::CloudWatch::Alarm::Collection
      expect(subject.first.name).to eq 'ec2-hoge-moge'
    end
  end
end
