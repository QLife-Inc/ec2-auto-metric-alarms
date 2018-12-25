require 'aws-sdk-s3'

class AlarmDefinitionRepository

  # @param [Aws::S3::Client] client
  def initialize(client)
    @s3 = Aws::S3::Resource.new(client: client)
    @bucket = @s3.bucket(Settings.definition_bucket_name)
    @prefix = Settings.definition_object_prefix
  end

  # @param [String] alarm_definition_name
  # @return [AlamrDefinitionTemplate]
  def get_alarm_definition(alarm_definition_name)
    key = @prefix + alarm_definition_name
    object = @bucket.object(key)
    unless object.exists?
      message = "s3://#{@bucket.name}/#{key} is not found."
      puts message
      return AlarmDefinitionTemplate.new("{\"error\":\"#{message}\"}")
    end
    AlarmDefinitionTemplate.new(object)
  end
end
