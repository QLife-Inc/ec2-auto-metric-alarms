require 'json'
require 'yaml'

class AlarmDefinitionResolver

  # @params [AlarmDefinitionRepository] repository
  def initialize(repository)
    @repository = repository
  end

  # @param [Aws::EC2::Instance] instance
  # @return [AlarmDefinitions]
  def resolve(instance)
    wrapped_instance = InstanceWrapper.new(instance)
    resolve_definition(wrapped_instance.alarm_definition, wrapped_instance)
  end

  private

  # @param [AlarmDefinitions] definitions
  # @param [Array<AlarmDefinition>]
  def resolve_definition(alarm_definition_name, instance)
    definition_hash = get_alarm_definitions(alarm_definition_name, instance)
    alarm_definitions = AlarmDefinitions.new(definition_hash)
    alarm_definitions = resolve_include_definitions(alarm_definitions, instance)
    alarm_definitions.remove_ignore_alarms
    alarm_definitions.definitions
  end

  # @param [AlarmDefinitions] definitions
  # @param [InstanceWrapper] instance
  # @return [AlarmDefinitions]
  def resolve_include_definitions(definitions, instance)
    include_definitions = definitions.include_definitions.map do |definition_name|
      resolve_definition(definition_name, instance) # recursive
    end
    include_definitions.flatten.each do |definition|
      definitions.add_definition(definition)
    end
    definitions
  end

  # @param [String] alarm_definition_name
  # @param [InstanceWrapper] instance
  # @return [Hash]
  def get_alarm_definitions(alarm_definition_name, instance)
    template = @repository.get_alarm_definition(alarm_definition_name)
    definition = template.render(instance)
    if template.yaml?
      YAML.load(definition, symbolize_names: true)
    else
      JSON.parse(definition, symbolize_names: true)
    end
  end
end
