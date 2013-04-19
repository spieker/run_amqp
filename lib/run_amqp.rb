require "run_amqp/version"
require 'active_support'
require 'run_amqp/publisher'
require 'run_amqp/subscriber'

module RunAmqp
  def self.new(exchange, options)
    RunAmqp::Publisher.new(exchange, options)
  end

  def self.logger
    @logger ||= Class.new do
      def debug(text, *args)
        puts text
        puts args
      end
      def info(text, *args)
        puts text
        puts args
      end
      def error(text, *args)
        puts text
        puts args
      end
    end.new
  end
end
