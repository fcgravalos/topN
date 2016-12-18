module TopN
  module Queue
    attr_reader :connection
    
    class MessagesCache
      def initialize(cache_config)
        @connection = nil
      end

      def save(message, status)
        raise "NotImplementedMethodError"
      end

      def get(message_id)
        raise "NotImplementedMethodError"
      end
    end
  end
end