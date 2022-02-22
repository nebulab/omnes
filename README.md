# Omnes

Simple pub/sub for Ruby.

Omnes is a simple Ruby library implementing the publish-subscribe pattern. This
pattern allows senders of messages to be decoupled from their receivers. An
Event Bus acts as a middleman where events are published while interested
actors can subscribe to them.

## Installation

`bundle add omnes`

## Example

```ruby
require 'omnes/bus'
Bus = Omnes::Bus.new
Bus.register(:change_customer_address_success)
Bus.register(:change_customer_address_failure)
Bus.subscribe(:change_customer_address_success, UpdateCustomerInsuranceSubscriber.new.method(:on_change_address_success))

class ChangeCustomerAddress
  attr_reader :bus
  
  def initialize(bus: Bus)
    @bus = bus
  end
  
  def call(customer, address)
    result = # Custom logic to change the customer address
    
    result.tap do
      if result.success?
        bus.publish(:change_customer_address_success, customer_id: customer.id, address: address)
      else
        bus.publish(:change_customer_address_failure, customer_id: customer.id, address: address)
      end
    end
  end
end

class UpdateCustomerInsuranceSubscriber
  def on_change_address_success(event)
    UpdateCustomerInsurance.new.call(customer_id: event[:customer_id], address: event[:address])
  end
end

customer = # ...
address = # ...
ChangeCustomerAddress.new.call(customer, address)
```

You can also mix in pub/sub capabilities to any instance:


```ruby
class ChangeCustomerAddress
  include Omnes
  
  def initialize
    register(:success)
    register(:failure)
  end
  
  def call(customer, address)
    result = # Custom logic to change the customer address
    
    result.tap do
      if result.success?
        publish(:success, customer_id: customer.id, address: address)
      else
        publish(:failure, customer_id: customer.id, address: address)
      end
    end
  end
end

change_customer_address = ChangeCustomerAddress.new
change_customer_address.subscribe(:success) do |event|
  UpdateCustomerInsuranceSubscriber.new.method(:on_change_address_success)
end
change_customer_address.call(customer, address)
```

## Rails Example
```ruby
# config/initializers/omnes.rb
require 'omnes/bus'
Bus = Omnes::Bus.new
Bus.register(:change_customer_address_success)
Bus.register(:change_customer_address_failure)
Bus.subscribe(:change_customer_address_success, UpdateCustomerInsuranceSubscriber.new.method(:on_change_address_success))

# app/subcribers/update_customer_insurance_subscriber.rb
class UpdateCustomerInsuranceSubscriber
  def on_change_address_success(event)
    UpdateCustomerInsurance.new.call(customer_id: event[:customer_id], address: event[:address])
  end
end

# app/controllers/customers_controller.rb
class CustomersController < ApplicationController
  def update_address
    customer = Customer.find(params[:id])
    address = params[:address]
    
    if ChangeCustomerAddress.new.call(customer, address)
      redirect_to root_path
    else
      render :edit
    end
  end
end
```



## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/omnes. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/omnes/blob/master/CODE_OF_CONDUCT.md).


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Omnes project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/omnes/blob/master/CODE_OF_CONDUCT.md).
