module RunAmqp
  class Subscriber
    include ActiveSupport::Callbacks
    define_callbacks :wait_loop

    def initialize(channel)
      @channel = channel
      @queues = []
      @shutdown = nil
    end

    def add(queue, subscribe_options = {})
      @queues << {
        :queue => queue,
        :subscribe_options => subscribe_options
      }
      self
    end

    def subscribe
      @queues.each do |queue|
        RunAmqp.logger.info "Subscribing", queue
        queue[:queue].subscribe(queue[:subscribe_options]) do |metadata, properties, payload|
          payload = ActiveSupport::JSON.decode(payload)
          begin
            RunAmqp.logger.info "Executing job", payload
            job = eval(payload['class']).new
            (payload['vars'] || {}).each do |key, value|
              job.instance_variable_set "@#{key}".to_sym, value
            end
            job.work()
            @channel.basic_ack(metadata.delivery_tag, false) if queue[:subscribe_options][:ack]
          rescue Exception => e
            RunAmqp.logger.error "Error while executing job", e
            # reject with requeue=false to route the message to the dead-letter-exchange
            @channel.basic_reject(metadata.delivery_tag, false) if queue[:subscribe_options][:ack]
          end
        end
      end

      loop do
        run_callbacks :wait_loop do
          return if shutdown?
        end
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
