# Fake classes so that we do not need RSpec1.x present for the tests to pass
module Spec
  module Runner
    module Formatter
      class BaseFormatter
      end
    end
  end
end

module Spec
  module Example
    class ExampleProxy
    end
  end
end

