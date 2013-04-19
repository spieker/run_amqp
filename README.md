# RunAmqp

TODO: Write a gem description

## Installation

Add this line to your application's Gemfile:

    gem 'run_amqp'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install run_amqp

## Usage

To put something into the queue, define the work first. The job class
must have a `work` method, where the work is done.

```ruby
class EmailSendingJob
  @queue = "amqp.example.emails"
  attr_accessor :to, :body

  def work
    MyMailer.example(@to, @body).deliver
  end
end
```

Now you can enqueue the job by passing it to amqp using RunAmqp.

```ruby
# ...
exchange = channel.direct 'my.amqp', :durable => true, :auto_delete => false
channel.queue('my.amqp.examples', :durable => true, :arguments => {
  :'x-dead-letter-exchange' => 'errors.amqp' # Exchange for exceptions
}).bind(exchange, :routing_key => 'example')

run_amqp = RunAmqp.new exchange, :routing_key => 'example'
run_amqp << EmailSendingJob.new('test@example.com', 'Hello World!!!')
```

To start the subscriber, create a run script `bin/run_amqp`, i.e.:

```ruby
connection = Bunny.new '...'
channel = connection.start
channel.prefetch(1000)
exchange = channel.direct 'my.amqp', :durable => true, :auto_delete => false
queues = []
queues << channel.queue('my.amqp.examples', :durable => true, :arguments => {
  :'x-dead-letter-exchange' => 'errors.amqp' # Exchange for exceptions
}).bind(exchange, :routing_key => 'example')

@subscriber = RunAmqp::Subscriber.new(channel, queues)
@subscriber.subscribe
```

Then run the workers by calling 

    bin/run_amqp

We sugest to use the DaemonSpawn gem to create a daemon script.

TODO: Write usage instructions here

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
