module Jason
  def self.spec(spec)
    Spec.new(spec)
  end

  class Spec
    attr_reader :specs, :misses

    def initialize(specs)
      @specs = specs
      @misses = []
    end

    def fits?(actual)
      @specs.each do |key, value|
        case key
        when :type
          match_type(value, actual)
        when :size
          match_size(value, actual)
        when :each
          match_each(value, actual)
        end

        break if @misses.any?
      end

      @misses.empty?
    end

    def match_type(type, value)
      matched = case type
      when :array, Array, "array", "Array"
        value.is_a?(Array)
      when :hash, Hash, "hash", "Hash"
        value.is_a?(Hash)
      when :string, String, "string", "String"
        value.is_a?(String)
      else
        value.is_a?(type)
      end

      @misses << "Type mismatch; Expected #{type}, got #{value.class}: #{value}" if !matched
    end

    def match_size(size, value)
      if !value.respond_to?(:size)
        @misses << "Size mismatch; #{value} has no size"
        return
      end

      @misses << "Size mismatch; Expected #{size}, got #{value.size}" if value.size != size
    end

    def match_each(mapping, value, root="")
      if mapping.is_a?(Array)
        return match_each_shallow(mapping, value)
      end

      value.each_with_index do |val, index|
        if !val.is_a?(Hash)
          @misses << "Each check failed. #{val} is no hash at [#{index}]"
          break
        end

        mapping.each do |key, attributes|
          if !val[key]
            @misses << "Each check failed. Key #{key} is missing at [#{index}]"
            break
          end

          if !val[key].is_a?(Hash)
            @misses << "Each check failed. #{key} is no hash at [#{index}]"
            break
          end

          attributes.each do |attr|
            if !val[key].has_key?(attr.to_s)
              @misses << "Each check failed. #{key}[#{attr}] is missing at [#{index}]"
              break
            end
          end
        end

        break if @misses.any?
      end
    end

    def match_each_shallow(attributes, value)
      value.each_with_index do |val, index|
        attributes.each do |attr|
          if !val.has_key?(attr.to_s)
            @misses << "Shallow each check failed. Key #{attr} is missing at [#{index}]"
            break
          end
        end

        break if @misses.any?
      end
    end
  end
end
