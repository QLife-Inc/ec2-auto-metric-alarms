require 'aws-sdk-ec2'
require 'aws-sdk-s3'
require 'aws-sdk-cloudwatch'

class AutoAlarmFacadeFactory

  # @param [Aws::EC2::Resource] ec2
  # @param [Aws::S3::Client] s3
  # @param [Aws::CloudWatch::Client] cloudwatch
  def self.create(ec2, s3, cloudwatch)
    return new(ec2, s3, cloudwatch).create
  end

  # @param [Aws::EC2::Resource] ec2
  # @param [Aws::S3::Client] s3
  # @param [Aws::CloudWatch::Client] cloudwatch
  def initialize(ec2, s3, cloudwatch)
    @ec2 = ec2
    @s3 = s3
    @cloudwatch = cloudwatch
  end

  def create
    AutoAlarmFacade.new(@ec2, resolver, resource)
  end

  private

  def resource
    AlarmResource.new(@cloudwatch)
  end

  def resolver
    AlarmDefinitionResolver.new(repository)
  end

  def repository
    AlarmDefinitionRepository.new(@s3)
  end
end
