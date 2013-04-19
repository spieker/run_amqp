require 'spec_helper'

describe RunAmqp::Subscriber do
  describe "#subscribe" do
    it "should subscribe to the given queues" do
      queue = Class.new do
        def subscribe(options, &block)
          block_given?.should == true
        end
      end.new
      mock.proxy(queue).subscribe(:ack => true)
      any_instance_of RunAmqp::Subscriber do |klass|
        mock(klass).shutdown? { true }
      end
      RunAmqp::Subscriber.new(nil, [queue]).subscribe
    end
  end

  it "should call the given worker if the block is called" do
    metadata = Class.new do
      def delivery_tag
        @delivery_tag ||= rand(100000)
      end
    end.new
    mock.proxy(metadata).delivery_tag.at_least(1)
    properties = {}
    payload = ActiveSupport::JSON.encode({
      'class' => 'ExampleMailJob',
      'vars' => {
        'to' => 'test@example.com',
        'subject' => 'This',
        'body' => 'is a test'
      }
    })

    channel = Class.new do
      def basic_ack(delivery_tag, multiple)
      end
    end.new
    mock(channel).basic_ack(metadata.delivery_tag, false)

    queue = Class.new do
      def initialize(metadata, properties, payload)
        @metadata = metadata
        @properties = properties
        @payload = payload
      end

      def subscribe(options, &block)
        block_given?.should == true
        block.call(@metadata, @properties, @payload)
      end
    end.new(metadata, properties, payload)
    mock.proxy(queue).subscribe(:ack => true)

    any_instance_of(ExampleMailJob) do |klass|
      mock.proxy(klass).work
      mock(klass).send_mail('test@example.com', 'This', 'is a test')
    end
    any_instance_of RunAmqp::Subscriber do |klass|
      mock(klass).shutdown? { true }
    end

    RunAmqp::Subscriber.new(channel, [queue]).subscribe
  end
  
  it "should reject and requeue failed messages" do
    metadata = Class.new do
      def delivery_tag
        @delivery_tag ||= rand(100000)
      end
    end.new
    mock.proxy(metadata).delivery_tag.at_least(1)
    properties = {}
    payload = ActiveSupport::JSON.encode({
      'class' => 'ExampleMailJob',
      'vars' => {
        'to' => 'test@example.com',
        'subject' => 'This',
        'body' => 'is a test'
      }
    })

    channel = Class.new do
      def basic_reject(delivery_tag, requeue)
      end
    end.new
    mock(channel).basic_reject(metadata.delivery_tag, false)

    queue = Class.new do
      def initialize(metadata, properties, payload)
        @metadata = metadata
        @properties = properties
        @payload = payload
      end

      def subscribe(options, &block)
        block_given?.should == true
        block.call(@metadata, @properties, @payload)
      end
    end.new(metadata, properties, payload)
    mock.proxy(queue).subscribe(:ack => true)

    any_instance_of(ExampleMailJob) do |klass|
      mock.proxy(klass).work
      mock(klass).send_mail('test@example.com', 'This', 'is a test') { raise "some exception" }
    end
    any_instance_of RunAmqp::Subscriber do |klass|
      mock(klass).shutdown? { true }
    end

    RunAmqp::Subscriber.new(channel, [queue]).subscribe
  end
end
