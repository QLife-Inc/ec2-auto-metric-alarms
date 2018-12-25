# @attr_reader [Array<String>] include_definitions
# @attr_reader [Array<AlarmDefinition>] definitions
class AlarmDefinitions
  attr_reader :include_definitions, :definitions

  # @param [Hash] definitions
  def initialize(definitions)
    @include_definitions = definitions[:include_definitions] || []
    @ignore_alarm_ids = definitions[:ignore_alarm_ids] || []
    @definitions = (definitions[:alarm_definitions] || []).map do |definition|
      AlarmDefinition.new(definition)
    end
  end

  # @param [AlarmDefinition] definition
  # @return [AlarmDefinitions]
  def add_definition(definition)
    if exists?(definition)
      return
    end
    @definitions += [definition]
  end

  def remove_ignore_alarms
    @ignore_alarm_ids.each {|alarm_id| remove_by_alarm_id(alarm_id)}
  end

  # @return [Boolean]
  def empty?
    @definitions.empty?
  end

  private

  # @param [String] alarm_id
  # @return [AlarmDefinitions]
  def remove_by_alarm_id(alarm_id)
    @definitions = @definitions.reject do |definition|
      definition.alarm_id === alarm_id
    end
  end

  # @param [AlarmDefinition] definition
  # @return [AlarmDefinition]
  def exists?(definition)
    @definitions.find { |existance| existance == definition }
  end
end
