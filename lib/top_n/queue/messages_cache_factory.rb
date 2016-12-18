require File.expand_path("#{__FILE__}/../redis_messages_cache")
module TopN
  module Queue
    SUPPORTED_CACHE_PROVIDERS = %w(redis)
    class MessagesCacheFactory
      def self.messages_cache(cache_provider, cache_config)
        raise "NotSupportedCache" unless SUPPORTED_CACHE_PROVIDERS.include? cache_provider
        case cache_provider
        when 'redis'
          redis_config = cache_config[:redis]
          return TopN::Queue::RedisMessagesCache.new(url: redis_config[:url],
                                                     key_expiration_time: redis_config[:key_expiration_time])
        end
      end
    end
  end
end