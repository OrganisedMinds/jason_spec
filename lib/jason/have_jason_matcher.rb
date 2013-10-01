require 'jason/spec'

module Jason
  class HaveJasonMatcher
    def initialize(specs)
      @specs = specs
    end

    def matches?(actual)
      @actual = actual.is_a?(String) ? Rufus::Json.decode(actual) : actual

      @misses = match_recursively(@specs, @actual)

      @misses.empty?
    end

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

    def failure_message
      "Jason misses: #{@misses.pretty_inspect}\n\tin #{@actual}"
    end

    def negative_failure_message
      "Jason has: #{@actual}"
    end
  end
end
