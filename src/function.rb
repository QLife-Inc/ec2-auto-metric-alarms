require_relative './libs/loader'

FACADE = AutoAlarmFacadeFactory.create(
  Aws::EC2::Resource.new,
  Aws::S3::Client.new,
  Aws::CloudWatch::Client.new
)

def lambda_handler(event:, context:)
  event_type = event['detail-type']
  instance_id = event.dig('detail', 'EC2InstanceId')
  case event_type
  when 'EC2 Instance Launch Successful'
    FACADE.set_alarms_to_instance_by_id(instance_id)
  when 'EC2 Instance Terminate Successful'
    FACADE.delete_alarms_by_instance_id(instance_id)
  else
    FACADE.set_alarm_to_instances_auto
  end
end
