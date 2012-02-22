
module Resque::Plugins
  module RoundRobin
    def filter_busy_queues qs
      busy_queues = Resque::Worker.working.map { |worker| worker.job["queue"] }.compact
      Array(qs.dup).compact - busy_queues
    end

    def rotated_queues
      @n ||= 0
      @n += 1
      rot_queues = queues
      if rot_queues.size > 0
        rot_queues.rotate(@n % rot_queues.size)
      else
        rot_queues
      end
    end

    def reserve_with_round_robin
      qs = rotated_queues
      qs = filter_busy_queues qs
      qs.each do |queue|
        log! "Checking #{queue}"
        if job = Resque::Job.reserve(queue)
          log! "Found job on #{queue}"
          return job
        end
      end

      nil
    rescue Exception => e
      log "Error reserving job: #{e.inspect}"
      log e.backtrace.join("\n")
      raise e
    end

    def self.included(receiver)
      receiver.class_eval do
        alias reserve_without_round_robin reserve
        alias reserve reserve_with_round_robin
      end
    end

  end # RoundRobin
end # Resque::Plugins

