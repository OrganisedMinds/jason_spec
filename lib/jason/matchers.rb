require 'jason/have_jason_matcher'

module Jason
  module Matchers
    def have_jason(spec)
      Jason::HaveJasonMatcher.new(spec)
    end
  end
end

RSpec.configure do |config|
  config.include Jason::Matchers
end

