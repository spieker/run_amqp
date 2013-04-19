module RunAmqp
  class Subscriber
    def initialize(channel, queues)
      @channel = channel
      @queues = queues
      @shutdown = nil
    end

    def subscribe
      @queues.each do |queue|
        RunAmqp.logger.info "Subscribing", queue
        queue.subscribe(:ack => true) do |metadata, properties, payload|
          payload = ActiveSupport::JSON.decode(payload)
          begin
            RunAmqp.logger.info "Executing job", payload
            job = eval(payload['class']).new
            (payload['vars'] || {}).each do |key, value|
              job.instance_variable_set "@#{key}".to_sym, value
            end
            job.work()
            @channel.basic_ack(metadata.delivery_tag, false)
          rescue Exception => e
            RunAmqp.logger.error "Error while executing job", e
            # reject with requeue=false to route the message to the dead-letter-exchange
            @channel.basic_reject(metadata.delivery_tag, false)
          end
        end
      end

      loop do
        break if shutdown?
        sleep(5)
      end
    end # subscribe
    
    def shutdown?
      @shutdown
    end

    def shutdown
      RunAmqp.logger.info "Shutting down ..."
      @shutdown = true
    end
  end # Subscriber
end # RunAmqp
