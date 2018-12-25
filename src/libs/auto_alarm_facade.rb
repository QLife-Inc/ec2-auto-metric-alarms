class AutoAlarmFacade
  include Logable

  EC2_FILTERS = [ { name: 'tag-key', values: [ Settings.definition_tag_key ] } ]

  # @param [Aws::EC2::Resource] ec2
  # @param [AlarmDefinitionResolver] resolver
  # @param [AlarmResource] resource
  def initialize(ec2, resolver, resource)
    @ec2 = ec2
    @resolver = resolver
    @resource = resource
  end

  def set_alarm_to_instances_auto
    @ec2.instances(filters: EC2_FILTERS).each do |instance|
      set_alarms_to_instance(instance)
    end
  end

  # @param [String] instance_id
  def set_alarms_to_instance_by_id(instance_id)
    instance = get_instance(instance_id)
    set_alarms_to_instance(instance)
  end

  # @param [String] instance_id
  def delete_alarms_by_instance_id(instance_id)
    instance = get_instance(instance_id)
    delete_alarms_of_instance(instance)
  end

  private

  # @param [Aws::EC2::Instance] instance
  def set_alarms_to_instance(instance)
    logger.debug("#{instance.id} にアラームを設定します")
    @resolver.resolve(instance).each do |definition|
      alarm = @resource.alarm(definition)
      if alarm.exists?
        alarm.update
        logger.info("アラーム '#{alarm.name}' を更新しました")
      else
        alarm.create
        logger.info("アラーム '#{alarm.name}' を作成しました")
      end
    end
  end

  # @param [Aws::EC2::Instance] instance
  def delete_alarms_of_instance(instance)
    logger.debug("#{instance.id} のアラームを削除します")
    @resolver.resolve(instance).each do |definition|
      alarm = @resource.alarm(definition)
      return unless alarm.exists?
      alarm.delete
      logger.info("アラーム '#{alarm.name}' を削除しました")
    end
    @resource.alarms.select { |alarm| alarm.name.include?(instance.id) }.each(&:delete)
  end

  def get_instance(instance_id)
    instance = @ec2.instance(instance_id)
    unless instance.exists?
      raise "EC2 instance is not found: #{instance_id}"
    end
    instance
  end
end
