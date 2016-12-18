require File.expand_path("#{__FILE__}/../sqs_mgr")
module TopN
  module Queue 
    class QueueMgrFactory
      # Enable a queue manager by adding the queue key name
      SUPPORTED_QUEUE_PROVIDERS = %w(sqs)
      def self.queue_mgr(queue_provider, queue_config)
        raise "NotSupportedQueue" unless SUPPORTED_QUEUE_PROVIDERS.include? queue_provider

        case queue_provider
        when 'sqs'
          sqs_config = queue_config[:sqs]
          return TopN::Queue::SqsMgr.new(sqs_config[:url],
                                         nil,
                                         aws_profile: sqs_config[:profile],
                                         aws_region: sqs_config[:region])
        end
      end
    end
  end
end