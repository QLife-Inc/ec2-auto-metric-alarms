require 'spec_helper'

describe AlarmDefinition do
  let(:alarm_id) { 'alarm_id' }
  let(:notification_type) { AlarmDefinition::NOTIFICATION_TYPE_EMERGENCY }
  let(:definition) do
    {
      alarm_id: alarm_id, notification_type: notification_type,
      alarm_name: 'テストアラーム',
      namespace: 'AWS/EC2',
      dimensions: [{ name: "InstanceId", value: "instance-id" }],
    }
  end
  let(:target) { described_class.new(definition) }

  describe 'initialize' do
    it 'has alarm_id' do
      expect(target.alarm_id).to eq alarm_id
    end
    it 'has notification_type' do
      expect(target.notification_type).to eq notification_type
    end
    it 'has definition without alarm_id and notification_type' do
      expect(target.definition).to eq(
        {
          alarm_name: 'テストアラーム',
          namespace: 'AWS/EC2',
          dimensions: [{ name: "InstanceId", value: "instance-id" }]
        }
      )
      expect(target.definition.key?(:alarm_id)).to be_falsey
      expect(target.definition.key?(:notification_type)).to be_falsey
    end
  end

  describe 'name' do
    subject { target.name }
    it { is_expected.to eq 'テストアラーム' }
  end

  describe '==' do
    let(:another) { described_class.new(alarm_id: alarm_id, alarm_name: 'ほげ') }

    subject { target == another }

    context 'when argument is nil' do
      let(:another) { nil }
      it { is_expected.to be_falsey }
    end

    context 'when alarm_id is same' do
      it { is_expected.to be_truthy }
    end
  end

  describe 'alarm_id_from_hash' do
    subject { target.alarm_id }

    context 'when alarm_id is missing' do
      let(:alarm_id) { nil }
      it { is_expected.to eq Digest::MD5.hexdigest(definition[:alarm_name]) }
    end
  end

  describe 'notification_type_from_hash' do
    subject { target.notification_type }

    context 'when notification_id is unknown literal' do
      let(:notification_type) { :hogehoge }
      it { is_expected.to eq AlarmDefinition::NOTIFICATION_TYPE_ORDINARY }
    end
  end

end
