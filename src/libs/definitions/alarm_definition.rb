require 'digest/md5'

class AlarmDefinition
  attr_reader :alarm_id, :notification_type, :definition

  NOTIFICATION_TYPE_EMERGENCY = 'emergency'
  NOTIFICATION_TYPE_ORDINARY = 'ordinary'
  NOTIFICATION_TYPES = [NOTIFICATION_TYPE_EMERGENCY, NOTIFICATION_TYPE_ORDINARY]

  # @param [Hash] definition
  def initialize(definition)
    @alarm_id = extract_alarm_id(definition)
    @notification_type = extract_notification_type(definition)
    @definition = definition
  end

  # @param [AlarmDefinition] definition
  def ==(definition)
    return false unless definition
    self.alarm_id === definition.alarm_id
  end

  def name
    @definition[:alarm_name]
  end

  private

  # @param [Hash] definition
  def extract_alarm_id(definition)
    alarm_id = definition.delete(:alarm_id)
    return alarm_id if alarm_id
    Digest::MD5.hexdigest(definition[:alarm_name])
  end

  # @param [Hash] definition
  def extract_notification_type(definition)
    notification_type = definition.delete(:notification_type)
    if NOTIFICATION_TYPES.include?(notification_type)
      notification_type
    else
      puts "#{notification_type} is unknown notification type, use #{NOTIFICATION_TYPE_ORDINARY}."
      NOTIFICATION_TYPE_ORDINARY
    end
  end
end
