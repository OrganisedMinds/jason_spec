require 'pp'
require 'jason/spec'

module Jason

  # Provides the have_jason functionality
  class HaveJasonMatcher

    # @param [Array,Hash] specs   List of specifications
    #
    # @example Specs by array
    #   # will check if the actual JSON has a foo and a bar key
    #   HaveJasonMatcher.new([ :foo, :bar ])
    #
    # @example Specs by hash
    #   # will check if the actual has an item object with a foo and a bar key
    #   HaveJasonMatcher.new( item: [ :foo, :bar ])
    #
    #   # will check if the actual has an item object with a foo key with a
    #   # bar value
    #   HaveJasonMatcher.new( item: { foo: "bar" } )
    #
    # @example Specs by hash with objects
    #   # will check if the actual has a attribute key with the value of
    #   # ruby_object.attribute()
    #   HaveJasonMatcher.new( ruby_object => [ :attribute ] )
    #
    # @example Specs by Jason.spec
    #   # will check the actual against the provided Jason::Spec
    #   HaveJasonMatcher.new( item: Jason.spec(type: Hash, fields: [ :foo, :bar ] ))
    #
    def initialize(specs)
      @specs = specs
    end

    # Check if the given JSON matches the specifications
    #
    # @param [JSON, Hash] actual   the value to check
    #
    # @return [Boolean]
    #
    def matches?(actual)
      @actual = actual.is_a?(String) ? Rufus::Json.decode(actual) : actual

      @misses = match_recursively(@specs, @actual)

      @misses.empty?
    end

    # recursivly walk over the specs and the actual to find any misses
    #
    # @param [Array,Hash] specs    List of specifications
    # @param [Array,Hash] actual   Provided data-structure (once JSON)
    #
    # @return [Hash] Hash with all the misses
    #
    def match_recursively(specs, actual, root="")
      actual ||= {}

      misses = {}

      if specs.is_a?(Array)
        specs.map(&:to_s).each do |key|
          res_key = root != "" ? "#{root}.#{key}" : "#{key}"
          if !actual.has_key? key
            misses[res_key] = :missing
          end
        end

        return misses
      end

      specs.each do |key, value|
        res_key = root != "" ? "#{root}.#{key}" : "#{key}"
        key = key.to_s if key.is_a?(Symbol)

        if key.is_a?(String)
          if value.is_a?(Jason::Spec)
            if !actual[key]
              misses[res_key] = { expected: { key: key }, got: :not_present }
              next
            end

            if !value.fits?(actual[key])
              misses[res_key] = { expected: value.opts, got: value.misses }
            end

          elsif value.is_a?(Array) or value.is_a?(Hash)
            begin
              misses.merge!(match_recursively(value, actual[key], res_key))
            rescue => ex
              $stderr.puts ex.backtrace.join("\n\t")
              misses[res_key] = { error: ex.message }
            end

          elsif actual[key] != value
            misses[res_key] = { expected: value, got: actual[key] }
          end

        else # the key is an object, the value is an array of methods
          value.each do |attr|
            res_key = root != "" ? "#{root}.#{attr}" : "#{attr}"

            if attr.is_a?(Hash)
              misses.merge!(match_recursively(attr, actual[attr], res_key))
              next
            end

            attr = attr.to_s

            expected = key.send(attr) rescue nil
            found    = actual[attr]

            if found
              if expected.is_a?(Time)
                # revert to seconds - microseconds do not compare
                found = Time.at(Time.parse(found).to_i)
                expected = Time.at(expected.to_i)

              elsif expected.is_a?(Date)
                found = Date.parse(found)

              end
            end

            if found != expected
              misses[res_key] = { expected: expected, got: found }
            end
          end
        end
      end

      return misses
    end

    # @return [String] Message to provide if it should have matched but didn't
    def failure_message
      "Jason misses: #{@misses.pretty_inspect}\n\tin #{@actual}"
    end

    # @return [String] Message to provide if it shouldn't have matched but did
    def negative_failure_message
      "Jason has: #{@actual}"
    end
  end
end
