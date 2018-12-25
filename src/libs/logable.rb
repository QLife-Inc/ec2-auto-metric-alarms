module Logable
  def logger
    @logger ||= Settings.logger
  end
end
