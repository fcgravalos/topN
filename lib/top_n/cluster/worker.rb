require 'daemons'
require 'logger'
require File.expand_path("#{__FILE__}/../../queue/queue_mgr_factory")
require File.expand_path("#{__FILE__}/../../queue/messages_cache_factory")

module TopN
  module Cluster
    class Worker
      attr_reader :chunks_queue_mgr
      attr_reader :results_queue_mgr
      attr_reader :messages_cache
      attr_reader :logger

      def initialize(chunks_queue_config, results_queue_config, messages_cache_config, logger = nil)
        @chunks_queue_mgr = TopN::Queue::QueueMgrFactory.queue_mgr(chunks_queue_config[:provider], 
                                                                   chunks_queue_config)
        @results_queue_mgr = TopN::Queue::QueueMgrFactory.queue_mgr(results_queue_config[:provider], 
                                                                    results_queue_config)
        @messages_cache = TopN::Queue::MessagesCacheFactory.messages_cache(messages_cache_config[:provider],
                                                                           messages_cache_config)
        @logger = logger || Logger.new(STDOUT)
      end

      def send_partial_result(partial_result, remaining_results)
        logger.info("PARTIAL_RESULT_SENT")
        results_queue_mgr.produce(body: partial_result,
                                  attributes: {
                                    pending_messages: remaining_results
                                  })

      end

      def process_chunk(chunk, id)
        messages_cache.save(id, 'PROCESSING')
        chunk_top = []
        File.foreach(chunk) do |line| 
          chunk_top << line.strip.to_i
        end
        logger.info "CHUNK_PROCESSED"
        messages_cache.save(id, 'PROCESSED')
        chunk_top
      end

      def already_processed?(id)
        status = messages_cache.get(id) =~/^PROCESS.*/
        status == 0 ? true : false
      end

      def start_chunk_processing
        chunks_queue_mgr.poll do |chunk, id|
          unless already_processed?(id)
            logger.info "NEW_CHUNK_RECEIVED: #{id}:#{chunk}"
            semaphore = Mutex.new
            thread = Thread.new {
              semaphore.synchronize {
                result = process_chunk(chunk, id)
                send_partial_result(result, 19.to_s)
                FileUtils.rm_f(chunk)
              }
            }
            thread.join
          end
        end
      end

      def self.start_worker(worker_id, worker_user, worker_group, log_prefix, chunks_queue_config, results_queue_config, messages_cache_config)
        puts "Starting node #{worker_id}..."
        task = Daemons.call(:multiple => true,
                            :app_name => "topn_worker_#{worker_id}",
                            :log_output => false,
                            :log_file => "#{log_prefix}-#{worker_id}.log",
                            :backtrace => true,
                            :dir_mode => :system,
                            :ontop => false) do
                              CurrentProcess.change_privilege(worker_user, worker_group)
                                worker = TopN::Cluster::Worker.new(chunks_queue_config, results_queue_config, messages_cache_config)
                                worker.start_chunk_processing
                            end
      end
    end
  end
end