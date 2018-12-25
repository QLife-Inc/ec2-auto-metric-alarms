class AlarmResource
  # @param [Aws::CloudWatch::Client] cloudwatch
  def initialize(cloudwatch)
    @cloudwatch = Aws::CloudWatch::Resource.new(client: cloudwatch)
  end

  # @param [AlarmDefinition] definition
  # @return [Alarm]
  def alarm(definition)
    Alarm.new(definition, @cloudwatch)
  end

  def alarms
    @cloudwatch.alarms
  end

  def find_by_name_prefix(prefix)
    @cloudwatch.alarms(alarm_name_prefix: prefix)
  end
end
