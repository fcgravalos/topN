#!/usr/bin/env ruby

require 'yaml'
require 'commander'
require 'active_support/core_ext/hash'
require 'daemons'
require File.expand_path("#{__FILE__}/../../lib/top_n/cluster/worker")
require File.expand_path("#{__FILE__}/../../lib/top_n/cluster/master")

class Cluster
  include Commander::Methods

  VERSION = 'v1.0.0'
  CONFIG = File.expand_path("#{__FILE__}/../../etc/config.yml")

  def read_config(config_file)
    begin
      YAML.load_file(config_file).deep_symbolize_keys
    rescue Errno::ENOENT => exception
      puts "Could not read config file: #{exception.message}"
      exit(1)
    end
  end

  def start_worker(worker_config)
    id = worker_config[:id]
    user = worker_config[:user]
    group = worker_config[:group]
    log_prefix = worker_config[:log_prefix]

    queue_config = worker_config[:queue_config]
    chunks_queue_config = queue_config[:chunks_queue]
    results_queue_config = queue_config[:results_queue]
    messages_cache_config = queue_config[:messages_cache]

    TopN::Cluster::Worker.start_worker(id, user, group, log_prefix, chunks_queue_config, results_queue_config, messages_cache_config)
  end

  def start_master(master_config)
  end

  def run
    program :name, 'topN Cluster'
    program :version, Cluster::VERSION
    program :description, 'CLI to initialize topN worker nodes'

    global_option('-c', '--config FILE', String, 'Path to config file.')
    command :start do |c|
      c.syntax = 'cluster start [options] <file> <n>'
      c.description = 'Start the cluster'

      c.option('-w', '--workers STRING', String, 'Number of workers.')
      c.option('-u', '--worker-user STRING', String, 'Unpriveleged user to run the worker.')
      c.option('-g', '--worker-group STRING', String, 'Unpriveleged group to run the worker.')
      c.option('-l', '--worker-log-prefix STRING', String, 'Path and prefix for the worker logs.')

      c.action do |args, options|
        fail("Wrong number of arguments, run 'cluster.rb --help'") unless args.length == 2 
        file = args.first
        n = args.last.to_i
        
        fail("File #{file} not found") unless File.exists?(file)
        options.default :config => CONFIG
        config = read_config(options.config)
        cluster_config = config[:cluster]
        queue_config = config[:queue]

        # User options takes precedence over config file
        worker_nodes = options.workers.to_i ||  cluster_config[:worker_nodes]
        worker_user = options.worker_user || cluster_config[:worker_user]
        worker_group = options.worker_group || cluster_config[:worker_group]
        worker_log_prefix = options.worker_log_prefix || cluster_config[:worker_log_prefix]

        (1..worker_nodes).each do |id|
          start_worker(id: id,
                      user: worker_user, 
                      group: worker_group, 
                      log_prefix: worker_log_prefix,
                      queue_config: queue_config)
        
        end

        top = TopN::Cluster::Master.top_n(File.absolute_path(file),
                           chunks_queue_config: queue_config[:chunks_queue],
                           results_queue_config: queue_config[:results_queue])

         puts "*** Top N numbers ***"
         puts top.sort.reverse[0...n]
         puts "*********************"
      end

      run!
    end
  end
end

Cluster.new.run if __FILE__ == $PROGRAM_NAME