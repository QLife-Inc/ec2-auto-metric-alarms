class InstanceWrapper

  # @param [Aws::EC2::Instance] instance
  def initialize(instance)
    @instance = instance
  end

  # @return [String]
  def name
    @name ||= tag_value('Name', @instance.id)
  end

  # @return [String]
  def alarm_definition
    @alarm_definition ||= tag_value(Settings.definition_tag_key)
  end

  # @param [String] key
  # @param [String] default_value
  # @return [String]
  def tag_value(key, default_value = nil)
    tag = tags.find { |t| t.key == key }
    if tag
      tag.value
    else
      default_value
    end
  end

  private

  def respond_to_missing?(name, include_private)
    return true if super
    @instance.respond_to?(name, include_private)
  end

  def method_missing(name, *args)
    if @instance.respond_to?(name)
      @instance.send(name, *args)
    else
      super
    end
  end
end
