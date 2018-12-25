require 'spec_helper'

describe Alarm do
  let(:alarm_id) { 'alarm_id' }
  let(:notification_type) { AlarmDefinition::NOTIFICATION_TYPE_EMERGENCY }
  let(:definition) do
    {
        alarm_id: alarm_id,
        notification_type: notification_type,
        alarm_name: 'test-alarm',
        namespace: 'AWS/EC2',
        dimensions: [{ name: "InstanceId", value: "instance-id" }],
    }
  end
  let(:alarm_definition) { AlarmDefinition.new(definition) }
  let(:metric_alarm) do
    {
      alarm_name: 'test-alarm',
      namespace: 'AWS/EC2',
      dimensions: [{ name: "InstanceId", value: "instance-id" }],
    }
  end
  let(:client) do
    client = instance_double('Aws::CloudWatch::Client')
    allow(client).to receive(:put_metric_alarm).and_return(metric_alarm)
    client
  end
  let(:alarm) do
    alarm = instance_double('Aws::CloudWatch::Alarm')
    allow(alarm).to receive(:exists?).and_return(true)
    allow(alarm).to receive(:delete)
    alarm
  end
  let(:cloudwatch) do
    resource = instance_double('Aws::CloudWatch::Resource')
    allow(resource).to receive(:client).and_return(client)
    allow(resource).to receive(:alarm).with(definition[:alarm_name]).and_return(alarm)
    resource
  end
  let(:target) { described_class.new(alarm_definition, cloudwatch) }
  let(:actions) do
    {
      alarm_actions: [Settings.emergency_topic_arn],
      ok_actions: [Settings.emergency_topic_arn],
    }
  end

  describe 'delete' do
    before { target.delete }
    subject { alarm }
    it { is_expected.to have_received(:delete).once }
  end

  describe 'create' do
    before { target.create }

    it do
      expect(client).to have_received(:put_metric_alarm)
                            .with(metric_alarm.merge(actions)).once
    end

    context 'when ordinary' do
      let(:notification_type) { AlarmDefinition::NOTIFICATION_TYPE_ORDINARY }
      let(:actions) do
        {
            alarm_actions: [Settings.ordinary_topic_arn],
            ok_actions: [Settings.ordinary_topic_arn],
        }
      end

      it do
        expect(client).to have_received(:put_metric_alarm)
                              .with(metric_alarm.merge(actions)).once
      end
    end
  end
end
