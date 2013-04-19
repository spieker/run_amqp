module RunAmqp
  class Publisher
    def initialize(exchange, options)
      @exchange = exchange
      @options = options
    end

    def <<(job)
      data = self.class.job_to_h(job)
      @exchange.publish(ActiveSupport::JSON.encode(data), @options)
    end

    private
    def self.job_to_h(job)
      variables = job.instance_variables

      result = {
        :class => job.class.name,
        :vars  => {}
      }

      variables.each do |var|
        result[:vars][var.to_s[1..-1].to_sym] = job.instance_variable_get(var)
      end

      result
    end
  end
end
