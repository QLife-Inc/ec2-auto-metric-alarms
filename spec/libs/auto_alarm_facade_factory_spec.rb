require 'spec_helper'

describe AutoAlarmFacadeFactory do
  let!(:ec2) { Aws::EC2::Resource.new(client: Aws::EC2::Client.new(stub_responses: true)) }
  let!(:s3) { Aws::S3::Client.new(stub_responses: true) }
  let!(:cw) { Aws::CloudWatch::Client.new(stub_responses: true) }

  describe 'create' do
    let!(:facade) { described_class.create(ec2, s3, cw) }

    it { expect(facade).to be_instance_of AutoAlarmFacade }
  end
end
