require 'spec_helper'

describe AlarmDefinitions do
  let(:empty_definition) do
    File.read(File.expand_path('./nesting-definitions.json', __dir__))
  end
  let(:cpu_util_json) do
    File.read(File.expand_path('./cpu-util.json', __dir__))
  end
  let(:target_json) { cpu_util_json }
  let(:target) { described_class.new(JSON.parse(target_json, symbolize_names: true)) }

  describe 'initialize' do
    it { expect(target.include_definitions).to be_empty }
    it { expect(target.definitions.size).to be 2 }
  end

  describe 'empty?' do
    let(:target_json) { empty_definition }
    it { expect(target).to be_empty }
  end

  describe 'add_definition' do
    let(:alarm_id) { 'additional-alarm-id' }
    let(:additional) do
      AlarmDefinition.new(alarm_id: alarm_id)
    end

    before { target.add_definition(additional) }

    context 'when alarm_id not exists' do
      it { expect(target.definitions.size).to be 3 }
    end

    context 'when alarm_id already exists' do
      let(:alarm_id) { 'emergency-cpu-util' }

      it { expect(target.definitions.size).to be 2 }
    end
  end

  describe 'remove_ignore_alarms' do
    let(:ignore_alarm_id) { 'emergency-cpu-util' }
    before do
      target.instance_variable_set(:@ignore_alarm_ids, [ignore_alarm_id])
      target.remove_ignore_alarms
    end

    subject { target.definitions }

    it { expect(subject.size).to be 1 }
    it { expect(subject.find { |d| d.alarm_id ==  ignore_alarm_id}).to be_nil }
  end

end
