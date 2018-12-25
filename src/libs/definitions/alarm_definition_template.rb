require 'erb'

class AlarmDefinitionTemplate
  attr_reader :body, :content_type

  # @params [Aws::S3::Object, String] data
  def initialize(data)
    if data.is_a?(String)
      @body = data
      @content_type = 'text/json'
    else
      @body = data.get.body.read.to_s
      @content_type = data.content_type&.downcase
    end
  end

  # @param [InstanceWrapper] instance
  # @return [String]
  def render(instance)
    ERB.new(body).result(binding)
  end

  def json?
    !yaml?
  end

  def yaml?
    content_type.include?('yaml')
  end
end
