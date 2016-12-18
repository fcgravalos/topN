require 'aws-sdk'
require 'json'
require File.expand_path("#{__FILE__}/../queue_mgr")

module TopN
  module Queue
    class SqsMgr < QueueMgr
      attr_reader :poller

      def initialize(queue, logger = nil, sqs_options = {})
        super(queue)

        sqs_defaults = {
          aws_profile: 'default',
          aws_region: 'eu-west-1'
        }
        sqs_options = sqs_defaults.merge(sqs_options)

        ENV['AWS_PROFILE'] = sqs_options[:aws_profile]
        aws_region = sqs_options[:aws_region]

        @connection = Aws::SQS::Client.new(region: aws_region)
        @poller = Aws::SQS::QueuePoller.new(queue, {client: connection})
      end

      def produce(message)
        begin
          connection.send_message(queue_url: queue,
                                  message_body: message[:body].to_json,
                                  message_attributes: {
                                    "PendingMessages" => {
                                      string_value: message[:attributes][:pending_messages],
                                      data_type: "Number"
                                    }
                                  })
        rescue Aws::SQS::Errors::ServiceError => excp
          logger.error("Could not send message.\
                        Reason: #{excp.message}\
                        Exiting...")
          exit(1)
        end
      end

      def consume
        begin
          message = connection.receive_message(
            queue_url: queue,
            attribute_names: ["All"], # accepts All, Policy, VisibilityTimeout, MaximumMessageSize, MessageRetentionPeriod, ApproximateNumberOfMessages, ApproximateNumberOfMessagesNotVisible, CreatedTimestamp, LastModifiedTimestamp, QueueArn, ApproximateNumberOfMessagesDelayed, DelaySeconds, ReceiveMessageWaitTimeSeconds, RedrivePolicy, FifoQueue, ContentBasedDeduplication
            message_attribute_names: ["PendingMessages"],
            max_number_of_messages: 10,
            visibility_timeout: 0,
            wait_time_seconds: 10,
          ).messages.last
          JSON.load(message.body)
          #message.nil? ? raise("Timeout Reached") : JSON.parse(message)
        rescue Aws::SQS::Errors::ServiceError => excp
          logger.error("Could not read from queue #{queue}.\
          Reason: #{excp.message}\
          Exiting...")
          exit(1)
        end
      end

      def poll
        poller.poll(wait_time_seconds: nil, max_number_of_messages: 10) do |batch|
          begin
            batch.each do |msg| 
              yield(JSON.load(msg.body), msg.message_id)
            end
          rescue StandardError => excp
            logger.error(excp.message)
            throw :skip_delete
          end
        end
      end
    end
  end
end