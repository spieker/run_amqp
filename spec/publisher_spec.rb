require 'spec_helper'

describe RunAmqp::Publisher do
  describe "#job_to_h" do
    it "should return a json containing all required variables" do
      job = ExampleMailJob.new.set('test@example.com', 'This', 'is a test')
      hash = RunAmqp::Publisher.send :job_to_h, job
      hash.should == {
        :class => 'ExampleMailJob',
        :vars => {
          :to => 'test@example.com',
          :subject => 'This',
          :body => 'is a test'
        }
      }
    end
  end

  describe "#publish" do
    it "should send the right content to the right exchange" do
      exchange = Class.new do
        def initialize
          @called = false
        end

        def publish(message, options = {})
          ActiveSupport::JSON.decode(message).should == {
            'class' => 'ExampleMailJob',
            'vars' => {
              'to' => 'test@example.com',
              'subject' => 'This',
              'body' => 'is a test'
            }
          }

          options[:routing_key].should == 'example'

          @called = true
        end

        def called?
          @called
        end
      end.new
      run_amqp = RunAmqp.new exchange, :routing_key => 'example'
      run_amqp << ExampleMailJob.new.set('test@example.com', 'This', 'is a test')
      exchange.should be_called
    end
  end
end
