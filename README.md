# Omnes

Pub/sub for Ruby.

Omnes is a Ruby library implementing the publish-subscribe pattern. This
pattern allows senders of messages to be decoupled from their receivers. An
Event Bus acts as a middleman where events are published while interested
parties can subscribe to them.

## Installation

`bundle add omnes`

## Usage

There're two ways to make use of the pub/sub features Omnes provides:

- Standalone, through an [`Omnes::Bus`](lib/omnes/bus.rb) instance:

```ruby
require "omnes"

bus = Omnes::Bus.new
```

- Mixing in the behavior in another class by including the [`Omnes`](lib/omnes.rb) module.

```ruby
require "omnes"

class Notifier
  include Omnes
end
```

The following examples will use the direct `Omnes::Bus` instance. The only
difference for the mixing use case is that the methods are directly called in
the including instance.

## Registering events

Before being able to work with a given event, its name (which must be a
`Symbol`) must be registered:

```ruby
bus.register(:order_created)
```

## Publishing events

An event can be anything responding to a method `:omnes_event_name`, which must match with a
registered name.

Typically, there're two main ways to generate events.
  
1. Unstructured events

An event can be generated at publication time, where you provide its name and a
payload to be consumed by its subscribers:

```ruby
bus.publish(:order_created, number: order.number, user_email: user.email)
```

In that case, an instance of [`Omnes::UnstructuredEvent`](lib/omnes/unstructured_event.rb) is generated
under the hood.

Unstructured events are straightforward to create and use, but they're harder
to debug as they're defined at publication time. On top of that, other
features, such as event persistence, can't be reliably built on top of them.

2. Instance-backed events

You can also publish an instance of a class including
[`Omnes::Event`](lib/omnes/event.rb). The only fancy thing it provides is an
OOTB event name generated based on the class name.

```ruby
class OrderCreatedEvent
  include Omnes::Event

  attr_reader :number, :user_email
  
  def initialize(number:, user_email:)
    @number = number
    @user_email = user_email
  end
end

event = OrderCreatedEvent.new(number: order.number, user_email: user.email)
bus.publish(event)
```

By default, an event name instance equals the event class name downcased,
underscored and with the `Event` suffix removed if present (`:order_created` in
the previous example). However, you can configure your own name generator based
on the event instance:

```ruby
event_name_as_class = ->(event) { event.class.name.to_sym } # :OrderCreatedEvent in the example
Omnes.config.event.name_builder = event_name_as_class
```

Instance-backed events provide a well-defined structure, and other features,
like event persistence, can be added on top of them.

## Subscribing to events

You can subscribe to a specific event to run some code whenever it's published.
The event is yielded to the subscription block:

```ruby
bus.subscribe(:order_created) do |event|
  # ...
end
```

For unstructured events, the published data is made available through the
`payload` method, although `#[]` can be used as a shortcut:

```ruby
bus.subscribe(:order_created) do |event|
  OrderCreationEmail.new.send(number: event[:number], email: event[:user_email])
  # OrderCreationEmail.new.send(number: event.payload[:number], email: event.payload[:user_email])
end
```

Otherwise, use the event instance according to its structure:

```ruby
bus.subscribe(:order_created) do |event|
  OrderCreationEmail.new.send(number: event.number, email: event.user_email)
end
```

The subscription code can also be given as anything responding to a method
`#call`.

```ruby
class OrderCreationEmailSubscription
  def call(event)
    OrderCreationEmail.new.send(number: event.number, email: event.user_email)
  end
end

bus.subscribe(:order_created, OrderCreationEmailSubscription.new)
```

However, see [Event subscribers](#event-subscribers) section bellow for a more powerful way
to define standalone event handlers.

### Global subscriptions

You can also create a subscription that will run for all events:

```ruby
class LogEventsSubscription
  attr_reader :logger
  
  def initialize(logger: Logger.new(STDOUT))
    @logger = logger
  end
  
  def call(event)
    logger.info("Event #{event.omnes_event_name} published")
  end
end

bus.subscribe_to_all(LogEventsSubscription.new)
```

### Custom matcher subscriptions

Custom event matchers can be defined. A matcher is something responding to
`#call` and taking the event as an argument. It must return `true` or `false`
to match or ignore the event.

```ruby
ORDER_EVENTS_MATCHER = ->(event) { event.omnes_event_name.start_with?(:order) }

bus.subscribe_with_matcher(ORDER_EVENTS_MATCHER) do |event|
  # ...
end
```

### Referencing subscriptions

For all subscription methods we've seen, an `Omnes::Subscription` instance is
returned. Holding that reference can be useful for [debugging](#debugging) and
[testing](#testing) purposes.

Often though, you won't have the reference at hand when you need it.
Thankfully, you can provide a subscription identifier on subscription time and
use it later to fetch the subscription instance from the bus. A subscription
identifier needs to be a `Symbol`:

```ruby
bus.subscribe(:order_created, OrderCreationEmailSubscription.new, id: :order_created_email)
subscription = bus.subscription(:send_confirmation_email)
```

## Event subscribers

Events subscribers offer a way to define event subscriptions from a custom
class.

In its simplest form, you can match an event to a method in the class.
  
```ruby
class OrderCreationEmailSubscriber
  include Omnes::Subscriber
  
  handle :order_created, with: :send_confirmation_email
  
  attr_reader :service
  
  def initialize(service: OrderCreationEmail.new)
    @service = service
  end

  def send_confirmation_email(event)
    service.send(number: event.number, email: event.user_email)
  end
end
```

You add the subscriptions by calling the `#subscribe_to` method on an instance:

```ruby
OrderCreationEmailSubscriber.new.subscribe_to(bus)
```

Equivalent to the subscribe methods we've seen above, you can also subscribe to
all events:

```ruby
class LogEventsSubscriber
  include Omnes::Subscriber
  
  handle_all with: :log_event
  
  attr_reader :logger
  
  def initialize(logger: Logger.new(STDOUT))
    @logger = logger
  end

  def log_event(event)
    logger.info("Event #{event.omnes_event_name} published")
  end
end
```

You can also handle the event with your own custom matcher:

```ruby
class OrderSubscriber
  include Omnes::Subscriber
  
  handle_with_matcher ORDER_EVENTS_MATCHER, with: :register_order_event
  
  def register_order_event(event)
    # ...
  end
end
```

Likewise, you can provide [identifiers to reference
subscriptions](#referencing-subscriptions):

```ruby
handle :order_created, with: :send_confirmation_email, id: :order_creation_email_subscriber
```

As you can subscribe multiple instances of a subscriber to the same bus, you
might need to create a different identifier for each of them. For those cases,
you can pass a lambda taking the subscriber instance:

```ruby
handle :order_created, with: :send_confirmation_email, id: ->(subscriber) { :"#{subscriber.id}_order_creation_email_subscriber" }
```

### Autodiscovering event handlers

You can let the event handlers to be automatically discovered.You need to
enable the `autodiscover` feature and prefix the event name with `on_` for your
handler name.

```ruby
class OrderCreationEmailSubscriber
  include Omnes::Subscriber[
    autodiscover: true
  ]
  
  # ...
  
  def on_order_created(event)
    # ...
  end
end
```

If you prefer, you can make `autodiscover` on by default:

```ruby
Omnes.config.subscriber.autodiscover = true
```

You can also specify your own autodiscover strategy. It must be something
callable, transforming the event name into the handler name.
  
```ruby
AUTODISCOVER_STRATEGY = ->(event_name) { event_name }

class OrderCreationEmailSubscriber
  include Omnes::Subscriber[
    autodiscover: true,
    autodiscover_strategy: AUTODISCOVER_STRATEGY
  ]
  
  # ...

  def order_created(event)
    # ...
  end
end
```

The strategy can also be globally set:

```ruby
Omnes.config.subscriber.autodiscover_strategy = AUTODISCOVER_STRATEGY
```

### Adapters

Subscribers are not limited to use a method as event handler. They can interact
with the whole instance context and leverage it to build adapters.

Omnes ships with a few of them.

#### Sidekiq adapter

The Sidekiq adapter allows creating a subscription to be processed as a
[Sidekiq](https://sidekiq.org) background job.

Sidekiq requires that the argument passed to `#perform` is serializable. By
default, the result of calling `#payload` in the event is taken.

```ruby
class OrderCreationEmailSubscriber
  include Omnes::Subscriber
  include Sidekiq::Job
  
  handle :order_created, with: Adapter::Sidekiq
  
  def perform(payload)
    OrderCreationEmail.send(number: payload["number"], email: payload["user_email"])
  end
end

bus = Omnes::Bus.new
bus.register(:order_created)
OrderCreationEmailSubscriber.new.subscribe_to(bus)
bus.publish(:order_created, "number" => order.number, "user_email" => user.email)
```

However, you can configure how the event is serialized thanks to the
`serializer:` option. It needs to be something callable taking the event as
argument:

```ruby
handle :order_created, with: Adapter::Sidekiq[serializer: :serialized_payload.to_proc]
```

You can also globally configure the default serializer:

```ruby
Omnes.config.subscriber.adapter.sidekiq.serializer = :serialized_payload.to_proc
```

You can delay the callback execution from the publication time with the `.in`
method (analogous to `Sidekiq::Job.perform_in`):

```ruby
handle :order_created, with: Adapter::Sidekiq.in(60)
```

#### ActiveJob adapter

The ActiveJob adapter allows creating a subscription to be processed as an
[ActiveJob](https://edgeguides.rubyonrails.org/active_job_basics.html)
background job.

ActiveJob requires that the argument passed to `#perform` is serializable. By
default, the result of calling `#payload` in the event is taken.

```ruby
class OrderCreationEmailSubscriber < ActiveJob
  include Omnes::Subscriber
  
  handle :order_created, with: Adapter::ActiveJob
  
  def perform(payload)
    OrderCreationEmail.send(number: payload["number"], email: payload["user_email"])
  end
end

bus = Omnes::Bus.new
bus.register(:order_created)
OrderCreationEmailSubscriber.new.subscribe_to(bus)
bus.publish(:order_created, "number" => order.number, "user_email" => user.email)
```

However, you can configure how the event is serialized thanks to the
`serializer:` option. It needs to be something callable taking the event as
argument:

```ruby
handle :order_created, with: Adapter::ActiveJob[serializer: :serialized_payload.to_proc]
```

You can also globally configure the default serializer:

```ruby
Omnes.config.subscriber.adapter.active_job.serializer = :serialized_payload.to_proc
```

#### Custom adapters

Custom adapters can be built. They need to implement a method `#call` taking
the instance of `Omnes::Subscriber`, the event and, optionally, the publication
context (see [debugging subscriptions](#subscription)).

Here's a custom adapter executing a subscriber method in a different
thread (we add an extra argument for the method name, and we partially apply it
at the definition time to obey the adapter requirements).

```ruby
THREAD_ADAPTER = lambda do |method_name, instance, event|
  Thread.new { instance.method(method_name).call(event) }
end

class OrderCreationEmailSubscriber
  include Omnes::Subscriber
  
  handle :order_created, with: THREAD_ADAPTER.curry[:order_created]
  
  def order_created(event)
    # ...
  end
end
```

Alternatively, adapters can be curried and only take the instance as an
argument, returning a callable taking the event. For instance, we could also
have defined the thread adapter like this:

```ruby
class ThreadAdapter
  attr_reader :method_name
  
  def initialize(method_name)
    @method_name = method_name
  end
  
  def call(instance)
    raise unless instance.respond_to?(method_name)
    
    ->(event) { instance.method(:call).(event) }
  end
end

# ...
handle :order_created, with: ThreadAdapter.new(:order_created)
# ...
```

## Unsubscribing & clearing

You can unsubscribe a given subscription by passing its
[reference](#referencing-subscriptions) to `Omnes::Bus#unsubscribe` (see how to
[reference subscriptions](#referencing-subscriptions)):

```ruby
subscription = bus.subscribe(:order_created, OrderCreationEmailSubscription.new)
bus.unsubscribe(subscription)
```

Sometimes you might need to leave your bus in a pristine state, with no events
registered or active subscriptions. That can be useful for autoloading in
development:

```ruby
bus.clear
bus.registry.event_names # => []
bus.subscriptions # => []
```

## Debugging

### Registration

Whenever you register an event, you get back an [`Omnes::Registry::Registration`](lib/omnes/registry.rb)
instance. It gives access to both the registered `#event_name` and the
`#caller_location` of the registration.

An `Omnes::Bus` contains a reference to its registry, which can be used to
retrieve a registration later on.

```ruby
bus.registry.registration(:order_created)
```

You can also use the registry to retrieve all registered event names:

```ruby
bus.registry.event_names
```

See [`Omnes::Registry`](lib/omnes/registry.rb) for other available methods.

### Publication

When you publish an event, you get back an
[`Omnes::Publication`](lib/omnes/publication.rb) instance. It contains some
attributes that allow observing what happened:

- `#event` contains the event instance that has been published.
- `#executions` contains an array of
  `Omnes::Execution`(lib/omnes/execution.rb). Read more below.
- `#context` is an instance of
  [`Omnes::PublicationContext`](lib/omnes/publication_context.rb).
  
`Omnes::Execution` represents a subscription individual execution. It contains
the following attributes:

- `#subscription` is an instance of [`Omnes::Subscription`](lib/omnes/subscripiton.rb).
- `#result` contains the result of the execution.
- `#benchmark` of the operation.
- `#time` is the time where the execution started.

`Omnes::PublicationContext` represents the shared context for all triggered
executions. See [Subscription][#subscription] for details.

### Subscription

If your subscription block or callable object takes a second argument, it'll
contain an instance of an
[`Omnes::PublicationContext`](lib/omnes/publication_context.rb). It allows you
to inspect what triggered a given execution from within that execution code. It
contains:

- `#caller_location` refers to the publication caller.
- `#time` is the time stamp for the publication.

```ruby
class OrderCreationEmailSubscriber
  include Omnes::Subscriber
  
  handle :order_created, with: :send_confirmation_email

  def send_confirmation_email(event, publication_context)
    # debugging
    abort(publication_context.caller_location.inspect)

    OrderCreationEmail.send(number: event.number, email: event.user_email)
  end
end
```

In case you're developing your own async adapter, you can call `#serialized` on
an instance of `Omnes::PublicationContext` to get a serialized version of it.
It'll return a `Hash` with `"caller_location"` and `"time"` keys, and the
respective `String` representations as values.

## Testing

Ideally, you wouldn't need big setups to test your event-driven behavior. You
could design your subscribers to use lightweight mocks for any external or
operation at the integration level. Example:

```ruby
if # test environment
  bus.subscribe(:order_created, OrderCreationEmailSubscriber.new(service: MockService.new)
else
  bus.subscribe(:order_created, OrderCreationEmailSubscriber.new)
end
```

Then, at the unit level, you can test your subscribers as any other class.

However, there's also a handy `Omnes::Bus#performing_only` method that allows
running a code block with only a selection of subscriptions as potential
callbacks for published events.

```ruby
creation_subscription = bus.subscribe(:order_created, OrderCreationEmailSubscriber.new)
deletion_subscription = bus.subscribe(:order_deleted, OrderDeletionSubscriber.new)
bus.performing_only(creation_subscription) do
  bus.publish(:order_created, number: order.number, user_email: user.email) # `creation_subscription` will run
  bus.publish(:order_deleted, number: order.number) # `deletion_subscription` won't run
end
bus.publish(:order_deleted, number: order.number) # `deletion_subscription` will run
```

Remember that you can get previous [subscription
references](#referencing-subscriptions) thanks to
subscription identifiers.

There's also a specialized `Omnes::Bus#performing_nothing` method that runs no
subscriptions for the duration of the block.

## Configuration

We've seen the relevant configurable settings in the corresponding sections.
You can also access the configuration in the habitual block syntax:

```ruby
Omnes.configure do |config|
  config.subscriber.adapter.sidekiq.serializer = :serialized_payload.to_proc
end
```

Finally, nested settings can also be set directly from the affected class. E.g.:

```ruby
Omnes::Subscriber::Adapter::Sidekiq.config.serializer = :serialized_payload.to_proc
```

## Recipes

### Rails

Create an initializer in `config/initializers/omnes.rb`:

```ruby
require "omnes"

Omnes.config.subscriber.autodiscover = true

Bus = Omnes::Bus.new

Rails.application.config.to_prepare do
  Bus.clear

  Bus.register(:order_created)

  OrderCreationEmailSubscriber.new.subscribe_to(Bus)
end
```

We can define `OrderCreationEmailSubscriber` in
`app/subscribers/order_creation_email_subscriber.rb`:

```ruby
# frozen_string_literal: true

class OrderCreationEmailSubscriber
  include Omnes::Subscriber

  def on_order_created(event)
    # ...
  end
end
```

Ideally, you'll publish your event in a [custom service
layer](https://www.toptal.com/ruby-on-rails/rails-service-objects-tutorial). If
that's not possible, you can publish it in the controller.

We strongly discourage publishing events as part of an `ActiveRecord` callback.
Subscribers should run code that is independent of the main business
transaction. As such, they shouldn't run within the same database transaction,
and they should be decoupled of persistence responsibilities altogether.

## Why is it called Omnes?

Why an Event Bus is called an _Event Bus_? It's a long story:

- The first leap leaves us with the hardware computer buses. They move data from one hardware component to another.
- The name leaked to the software to describe architectures that communicate parts by sending messages, like an Event Bus.
- That was given as an analogy of buses as vehicles, where not data but people are transported.
- _Bus_ is a clipped version of the Latin _omnibus_. That's what buses used to be called (and they're still called like that in some places, like Argentina).
- _Bus_ stands for the preposition _for_, while _Omni_ means _all_. That's _for
  all_, but, for some reason, we decided to keep the part void of meaning.
- Why were they called _omnibus_? Let's move back to 1823 and talk about a man named Stanislas Baudry.
- Stanislas lived in a suburb of Nantes, France. There, he ran a corn mill.
- Hot water was a by-product of the mill, so Stanislas decided to build a spa business.
- As the mill was on the city's outskirts, he arranged some horse-drawn
  transportation to bring people to his spa.
- It turned out that people weren't interested in it, but they did use the carriage to go to and fro.
- The first stop of the service was in front of the shop of a hatter called
  __Omnes__.
- Omnes was a witty man. He'd named his shop with a pun on his Latin-sounding
  name: _Omnes Omnibus_. That means something like _everything for everyone_.
- Therefore, people in Nantes started to call _Omnibus_ to the new service.

So, it turns out we call it the "Event Bus" because presumably, the parents of
Omnes gave him that name. So, the name of this library, it's a tribute to
Omnes, the hatter.

By the way, in case you're wondering, Stanislas, the guy of the mill, closed
both it and the spa to run his service.
Eventually, he moved to Paris to earn more money in a bigger city.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`rake spec` to run the tests. You can also run `bin/console` for an interactive
prompt that will allow you to experiment.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/nebulab/omnes. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/nebulab/omnes/blob/master/CODE_OF_CONDUCT.md).


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Omnes project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/nebulab/omnes/blob/master/CODE_OF_CONDUCT.md).
