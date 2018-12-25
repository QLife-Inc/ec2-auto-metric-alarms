class Alarm
  extend Forwardable
  include Logable

  def_delegators :alarm, :exists?, :delete, :alarm_arn
  def_delegators :@definition, :name

  # @param [AlarmDefinition] definition
  # @param [Aws::CloudWatch::Resource] cloudwatch
  def initialize(definition, cloudwatch)
    @definition = definition
    @cloudwatch = cloudwatch
  end

  def create
    if @definition.notification_type === AlarmDefinition::NOTIFICATION_TYPE_EMERGENCY
      topics = [ Settings.emergency_topic_arn ]
    else
      topics = [ Settings.ordinary_topic_arn ]
    end
    actions = { ok_actions: topics, alarm_actions: topics }
    request = actions.merge(@definition.definition)
    response = @cloudwatch.client.put_metric_alarm(request)
    logger.info("アラームを設定しました: name: #{name}, alarm: #{response.to_json}")
  end
  alias update create

  private

  # @return [Aws::CloudWatch::Alarm]
  def alarm
    @alarm ||= @cloudwatch.alarm(name)
  end
end
