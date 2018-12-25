class Settings
  class << self
    # @return [String]
    def definition_bucket_name
      @definition_bucket_name ||= ENV['DEFINITION_BUCKET_NAME']
    end

    # @return [String]
    def definition_object_prefix
      @definition_object_prefix ||= \
          normalize_prefix(ENV['DEFINITION_OBJECT_PREFIX'])
    end

    # @return [String]
    def definition_tag_key
      @definition_tag_key ||= ENV['DEFINITION_TAG_KEY']
    end

    # @return [String]
    def emergency_topic_arn
      @emergency_topic_arn ||= ENV['EMERGENCY_TOPIC_ARN']
    end

    # @return [String]
    def ordinary_topic_arn
      @ordinary_topic_arn ||= ENV['ORDINARY_TOPIC_ARN']
    end

    # @return [Logger]
    def logger
      @logger ||= Logger.new(STDOUT, level: log_level)
    end

    # # @return [Pathname]
    # def template_cache_path
    #   @cache_path ||= Pathname.new(ENV['LAMBDA_TASK_ROOT']) + 'cache'
    # end

    private

    # @return [String]
    def normalize_prefix(prefix)
      return prefix unless prefix
      (prefix.end_with?('/') ? prefix.chop : prefix) + '/'
    end

    # @return [Integer]
    def log_level
      @log_level ||= Logger::Severity.const_get(ENV['LOG_LEVEL']&.upcase || 'INFO')
    end
  end
end
