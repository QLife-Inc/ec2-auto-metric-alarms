require 'spec_helper'

describe InstanceWrapper do
  let(:instance_id) { 'i-0123456789' }
  let(:name) { nil }
  let(:alarm_definition_name) { nil }
  let(:tags) do
    tags = []
    tags << OpenStruct.new(key: 'Name', value: name) unless name.nil?
    unless alarm_definition_name.nil?
      tags << OpenStruct.new(key: 'AlarmDefinitionName',
                             value: alarm_definition_name)
    end
    tags
  end
  let(:instance) do
    Aws::EC2::Instance.new(id: instance_id, data: { tags: tags, image_id: 'ami-12345' })
  end
  let(:target) { described_class.new(instance) }

  describe 'initialize' do
    let(:wrapper) { described_class.new('hoge') }
    subject { wrapper.instance_variable_get(:@instance) }

    it { is_expected.to eq 'hoge' }
  end

  describe 'tag_value' do
    let(:tag_key) { 'HogeKey' }
    let(:tag_value) { 'HogeHoge' }
    let(:default_value) { 'default_value' }
    let(:tags) { [ OpenStruct.new(key: tag_key, value: tag_value) ] }

    subject { target.tag_value(tag_key, default_value) }

    context 'when has tag key' do
      it { is_expected.to eq tag_value }
    end

    context 'when tag is missing' do
      let(:tags) { [] }
      it { is_expected.to eq default_value }
    end
  end

  describe 'name' do
    let(:name) { 'HogeInstance' }

    subject { target.name }

    it { is_expected.to eq name }
  end

  describe 'alarm_definition' do
    let(:alarm_definition_name) { 'hoge-hoge' }

    before do
      Settings.instance_variable_set(:@definition_tag_key, 'AlarmDefinitionName')
    end

    subject { target.alarm_definition }

    it { is_expected.to eq alarm_definition_name }
  end

  describe 'method_missing' do
    context 'when instance has method' do
      it { expect(target.image_id).to eq 'ami-12345' }
    end

    context 'when instance not have method' do
      subject { -> { target.hoge } }
      it { is_expected.to raise_error(NoMethodError) }
    end
  end
end
