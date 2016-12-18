require 'redis'
require File.expand_path("#{__FILE__}/../messages_cache")
module TopN
  module Queue
    attr_reader :key_expiration_time

    class RedisMessagesCache < MessagesCache
      def initialize(redis_config)
        @connection = Redis.new(url: redis_config[:url])
        @key_expiration_time = redis_config[:key_expiration_time]
      end

      def save(message_id, status)
        key = "message_id:#{message_id}"
        @connection.hmset(key, 'status', status)
        @connection.expire(key, @key_expiration_time)
      end

      def get(message_id)
        key = "message_id:#{message_id}"
        @connection.hmget(key, 'status').last
      end
    end
  end
end