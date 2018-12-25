require 'spec_helper'

class AlarmDefinitionRepositoryMock
  def get_alarm_definition(alarm_definition_name)
    body = File.read(File.expand_path(alarm_definition_name, __dir__))
    content_type = alarm_definition_name.end_with?('json') ? 'text/json' : 'text/yaml'
    mock_object = OpenStruct.new(get: OpenStruct.new(body: OpenStruct.new(read: body)), content_type: content_type)
    AlarmDefinitionTemplate.new(mock_object)
  end
end

describe AlarmDefinitionResolver do
  let(:alarm_definition_name) { 'cpu-util.json' }
  let(:instance_id) { 'i-12345' }
  let(:instance_name) { 'aInstance' }
  let(:tags) do
    [
      OpenStruct.new(key: 'Name', value: instance_name),
      OpenStruct.new(key: 'DefName', value: alarm_definition_name),
    ]
  end
  let(:instance) do
    Aws::EC2::Instance.new(id: instance_id, data: { tags: tags })
  end

  let(:target) { described_class.new(AlarmDefinitionRepositoryMock.new) }

  before do
    Settings.instance_variable_set(:@definition_tag_key, nil)
    ENV['DEFINITION_TAG_KEY'] = 'DefName'
  end

  describe 'resolve' do
    let(:results) { target.resolve(instance) }

    context 'when simple definition' do
      it do
        expect(results.size).to be 2

        # @type [AlarmDefinition] emergency
        emergency = results.find {|d| d.notification_type == AlarmDefinition::NOTIFICATION_TYPE_EMERGENCY}
        expect(emergency.definition[:alarm_name]).to eq "ec2-#{instance_id}-emergency-cpu-util"
        expect(emergency.definition[:alarm_description]).to eq "#{instance_name} CPU使用率が 30 分間 90 % を超えていたら通知"

        # @type [AlarmDefinition] ordinary
        ordinary = results.find {|d| d.notification_type == AlarmDefinition::NOTIFICATION_TYPE_ORDINARY}
        expect(ordinary.definition.dig(:dimensions)&.first[:value]).to eq instance_id
      end
    end

    context 'when simple definition of yaml' do
      let(:alarm_definition_name) { 'cpu-util.yml' }
      it do
        expect(results.size).to be 2

        # @type [AlarmDefinition] emergency
        emergency = results.find {|d| d.notification_type == AlarmDefinition::NOTIFICATION_TYPE_EMERGENCY}
        expect(emergency.definition[:alarm_name]).to eq "ec2-#{instance_id}-emergency-cpu-util"
        expect(emergency.definition[:alarm_description]).to eq "#{instance_name} CPU使用率が 30 分間 90 % を超えていたら通知"

        # @type [AlarmDefinition] ordinary
        ordinary = results.find {|d| d.notification_type == AlarmDefinition::NOTIFICATION_TYPE_ORDINARY}
        expect(ordinary.definition.dig(:dimensions)&.first[:value]).to eq instance_id
      end
    end

    context 'when nested definition' do
      let(:alarm_definition_name) { 'nesting-definitions.json' }

      it do
        expect(results.size).to be 1

        # @type [AlarmDefinition] emergency
        emergency = results.find {|d| d.notification_type == AlarmDefinition::NOTIFICATION_TYPE_EMERGENCY}
        expect(emergency).to be_nil

        # @type [AlarmDefinition] ordinary
        ordinary = results.find {|d| d.notification_type == AlarmDefinition::NOTIFICATION_TYPE_ORDINARY}
        expect(ordinary.definition.dig(:dimensions)&.first[:value]).to eq instance_id
      end
    end

  end
end
