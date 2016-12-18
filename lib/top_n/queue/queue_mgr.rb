module TopN
  module Queue
    class QueueMgr
      attr_reader :queue
      attr_reader :connection
      attr_reader :logger

      def initialize(queue, logger = nil)
        @queue = queue
        @connection = nil
        @logger = logger || Logger.new(STDOUT)
      end

      def produce(message)
        raise "MethodNotImplementedError"
      end

      def consume
        raise "MethodNotImplementedError"
      end

      def poll
        raise "MethodNotImplementedError"
      end
    end
  end
end
