module Jason

  # @returns [Jason::Spec] Specifications for JSON checking
  def self.spec(spec)
    Spec.new(spec)
  end

  # Class for holding and checking specifications for a JSON structure
  #
  # @attr_reader [Hash] specs Stored specifications
  # @attr_reader [Array] misses List of collected failures
  #
  class Spec
    attr_reader :specs, :misses

    # @param [Hash] specs   Specifications for testing
    # @option specs [Class]   :type    Type of the actual
    # @option specs [Integer] :size    Size of the actual
    # @option specs [Array]   :each    Each element in actual should have
    #                                  these fields
    # @option specs [Array]   :fields  Fields that should be present in actual
    #
    def initialize(specs)
      @specs = specs
      @misses = []
    end

    # Check if the specs fit the actual
    #
    # @returns [Boolean]
    #
    def fits?(actual)
      @specs.each do |key, value|
        case key
        when :type
          match_type(value, actual)
        when :size
          match_size(value, actual)
        when :each
          match_each(value, actual)
        when :fields
          match_fields(value, actual)
        end

        break if @misses.any?
      end

      @misses.empty?
    end

    # Does the value match the requested type, populates @misses in failure
    #
    # @param [Symbol, String, Class] type  What type should the value be.
    #        Supported strings are: hash, array, string or boolean
    #
    # @param [Object] value
    #
    # @example Hash
    #   match_type(:hash,   { foo: "bar" }) # match
    #   match_type("array", [0,1,2])        # match
    #   match_type(String,  "meh")          # match
    #   match_tyoe(:booelean, false)        # match
    #
    # @return [void]
    def match_type(type, value)
      matched = case type
      when :array, "array", "Array"
        value.is_a?(Array)
      when :hash, "hash", "Hash"
        value.is_a?(Hash)
      when :string, "string", "String"
        value.is_a?(String)
      when :boolean, "boolean", "Boolean"
        value.is_a?(TrueClass) || value.is_a?(FalseClass)
      else
        value.is_a?(type)
      end

      @misses << "Type mismatch; Expected #{type}, got #{value.class}: #{value}" if !matched
    end

    # Does the value match the requested size. Populates @misses in failure
    #
    # @param [Integer] size  The needed size
    # @param [Object] value
    # @return [void]
    #
    def match_size(size, value)
      if !value.respond_to?(:size)
        @misses << "Size mismatch; #{value} has no size"
        return
      end

      @misses << "Size mismatch; Expected #{size}, got #{value.size}" if value.size != size
    end

    # Does the value match the requested size. Populates @misses in failure
    #
    # @param [Integer] size  The needed size
    # @param [Object] value
    # @return [void]
    #
    def match_each(mapping, value, root="")
      if mapping.is_a?(Array)
        return match_each_shallow(mapping, value)
      end

      value.each_with_index do |val, index|
        if !val.is_a?(Hash)
          @misses << "Each check failed. #{val} is no hash at #{root}[#{index}]"
          break
        end

        mapping.each do |key, fields|
          miss_key = root == "" ? key : "#{root}.#{key}"

          if !val[key]
            @misses << "Each check failed. Key #{miss_key} is missing at #{root}[#{index}]"
            break
          end

          if !val[key].is_a?(Hash)
            @misses << "Each check failed. #{miss_key} is no hash at #{root}[#{index}]"
            break
          end

          if fields.is_a?(Hash)
            match_each(fields,val[key],miss_key)
            next
          end

          fields.each do |attr|
            if !val[key].has_key?(attr.to_s)
              @misses << "Each check failed. #{miss_key}[#{attr}] is missing at #{root}[#{index}]"
              break
            end
          end
        end

        break if @misses.any?
      end
    end

    # match each only for fields
    # @param [Array<Symbol>] fields  list of required fields
    # @param [Array] list of objects that carry fields
    # @return [void]
    #
    def match_each_shallow(fields, value)
      value.each_with_index do |val, index|
        fields.each do |attr|
          if !val.has_key?(attr.to_s)
            @misses << "Shallow each check failed. Key #{attr} is missing at [#{index}]"
            break
          end
        end

        break if @misses.any?
      end
    end

    # Match fields on a hash
    # @param [Array<Symbol>] fields  list of required fields
    # @param [Hash] value  Hash to check fields in
    # @return [void]
    #
    def match_fields(fields, value)
      fields.each do |attr|
        if !value.has_key(attr.to_s)
          @misses << "Fields check failed. Key #{attr} is not present"
          break
        end
      end
    end

  end
end
