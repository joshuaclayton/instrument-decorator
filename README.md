# Instrument::Decorator

This gem provides a way to decorate methods with instrumentation. Its primary
use case is to send information about invoked methods and their arguments to
OpenTelemetry collectors.

## Usage

Instrumentation is provided via a decorator that can be mixed into your classes.

### Instrumenting an instance method

```ruby
class Example
  include Instrument::Decorator

  instrument def example_method
    # Your method implementation here
  end
end
```

### Instrumenting a class method

```ruby
class Example
  include Instrument::Decorator

  instrument_class_method def self.example_method
    # Your method implementation here
  end
end
```

This sends any `args` or `kwargs` data, along with any exception information
that gets raised during the execution of the method.

Name information sent follow Ruby's `ClassName#method_name` or
`ClassName.method_name` conventions.

## Tests

First, ensure your `.env` is set up correctly:

```sh
cp .env.example .env
```

To verify data is spent to an OTel collector, start a Jaeger instance via Docker:

```sh
docker run --name jaeger \
  -e COLLECTOR_ZIPKIN_HOST_PORT=:9411 \
  -e COLLECTOR_OTLP_ENABLED=true \
  -p 6831:6831/udp \
  -p 6832:6832/udp \
  -p 5778:5778 \
  -p 16686:16686 \
  -p 4317:4317 \
  -p 4318:4318 \
  -p 14250:14250 \
  -p 14268:14268 \
  -p 14269:14269 \
  -p 9411:9411 \
  jaegertracing/all-in-one:latest
```

Open up your browser to `http://localhost:16686` to view the Jaeger UI.

Finally, run tests:

```sh
bin/test
```

This will run the test suite with a null tracer (which has no behavior) and with an OTel tracer.

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/joshuaclayton/instrument-decorator. This project is intended
to be a safe, welcoming space for collaboration, and contributors are expected
to adhere to the [code of
conduct](https://github.com/joshuaclayton/instrument-decorator/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT
License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Instrument::Decorator project's codebases, issue
trackers, chat rooms and mailing lists is expected to follow the [code of
conduct](https://github.com/joshuaclayton/instrument-decorator/blob/main/CODE_OF_CONDUCT.md).
