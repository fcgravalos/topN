require 'logger'
require File.expand_path("#{__FILE__}/../../queue/queue_mgr_factory")
require File.expand_path("#{__FILE__}/../../file_processor")

module TopN
  module Cluster
    class Master
      attr_reader :chunks_queue_mgr
      attr_reader :results_queue_mgr
      attr_accessor :top_numbers

      def initialize(chunks_queue_config, results_queue_config)
        @chunks_queue_mgr = TopN::Queue::QueueMgrFactory.queue_mgr(
          chunks_queue_config[:provider],
          chunks_queue_config)
        @results_queue_mgr = TopN::Queue::QueueMgrFactory.queue_mgr(
          results_queue_config[:provider],
          results_queue_config)
        @top_numbers = []
      end

      def send_processing_job(job, remaining_messages)
        chunks_queue_mgr.produce(
          body: job,
          attributes: { 
            pending_messages: remaining_messages.to_s
          }
        )
      end

      def get_partial_result
        results_queue_mgr.consume
      end

      def reduce
        chunk_result = get_partial_result
        @top_numbers |= chunk_result
        top_numbers
      end

      def map(filename)
        fp = TopN::FileProcessor.new(filename)
        chunks = fp.split_file
        remaining_chunks = chunks.length
        chunks.each do |chunk|
          semaphore = Mutex.new
          thread = Thread.new {
            semaphore.synchronize {
              send_processing_job(chunk, remaining_chunks)
              reduce
            }
          }
          thread.join
        end
        top_numbers
      end

      def self.top_n(filename, master_configuration)
        chunks_queue_config = master_configuration[:chunks_queue_config]
        results_queue_config = master_configuration[:results_queue_config]
        master_node = TopN::Cluster::Master.new(chunks_queue_config, results_queue_config)
        master_node.map(filename)
      end
    end
  end
end
