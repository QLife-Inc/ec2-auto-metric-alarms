require 'spec_helper'

describe AutoAlarmFacade do
  def create_instance(id, name, alarm_definition_name, exists = true)
    tags = [
      OpenStruct.new(key: 'Name', value: name),
      OpenStruct.new(key: Settings.definition_tag_key, value: alarm_definition_name)
    ]
    instance = OpenStruct.new(id: id, tags: tags)
    allow(instance).to receive(:exists?).and_return(exists)
    instance
  end

  let(:exists) { true }
  let(:instance) { create_instance('i-12345', 'dummy', 'dummy-alarm-definition', exists) }
  let(:ec2) { instance_double('AWS::EC2::Resource', instances: [instance], instance: instance) }
  let(:definition) do
    AlarmDefinition.new(
      alarm_id: 'alarm-id',
      notification_type: 'emergency',
      alarm_name: 'dummy-alarm'
    )
  end
  let(:resolver) { instance_double('AlarmDefinitionRsolver', resolve: [definition]) }
  let(:alarm) do
    instance_double('Alarm', exists?: exists, name: definition.name, update: nil, create: nil)
  end
  let(:resource) { instance_double('AlarmResource', alarm: alarm) }
  let(:target) { described_class.new(ec2, resolver, resource) }

  describe 'set_alarms_to_instance' do
    before { target.send(:set_alarms_to_instance, instance) }

    context 'when alarm is already exists' do
      it 'called update' do
        expect(alarm).to have_received(:update).once
      end
    end

    context 'when alarm is not exists' do
      let(:exists) { false }
      it 'called create' do
        expect(alarm).to have_received(:create).once
      end
    end
  end

  describe 'set_alarm_to_instances_auto' do
    before do
      allow(target).to receive(:set_alarms_to_instance).and_return(true)
      target.set_alarm_to_instances_auto
    end

    subject { target }

    it do
      is_expected.to have_received(:set_alarms_to_instance).once
    end
  end
end
