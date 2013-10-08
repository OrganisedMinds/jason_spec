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
      @misses = [] # reset misses
      @specs.each do |key, value|
        method = :"match_#{key}"
        if !respond_to?(method)
          @misses << "Unknown spec: #{key}"
          break
        end

        begin
          self.send(method, value, actual)
        rescue => ex
          @misses << "Error in #{key} check: #{ex.class}: #{ex.message}"
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
      when :array, :Array, "array", "Array"
        value.is_a?(Array)
      when :hash, :Hash, "hash", "Hash"
        value.is_a?(Hash)
      when :string, "string", "String"
        value.is_a?(String)
      when :boolean, :Boolean, "boolean", "Boolean"
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

      hit = if size.is_a?(Fixnum)
        value.size == size
      elsif size.is_a?(Range)
        size.cover?(value.size)
      elsif size.is_a?(Array)
        size.include?(value.size)
      end

      @misses << "Size mismatch; Expected #{size}, got #{value.size}" if !hit
    end

    # Does the array contain each of the requested specs
    #
    # @param [Hash,Array,Jason::Spec] mapping  What the array should contain
    # @param [Array] value  Array to check
    # @param [Symbol] type  How to check:
    #   * :each - all items must match)
    #   * :any - at least one item must match)
    #   * :none - no item may match
    # @param [String] root  Root for recursive checks
    #
    # @return [void]
    #
    # @example Shallow check for key
    # match_each([ :id ], [ { 'id' => 1 }])
    #
    # @example Shallow check for key with any
    # match_each([ :id ], [ { 'id' => 1 }, { 'bar' => 'beer' } ], :any )
    #
    # @example Shallow check for key with none
    # not match_each([ :id ], [ { 'id' => 1 }, { 'bar' => 'beer' } ], :any )
    #
    # @example Deep check
    # match_each(
    #   { item: [ :id, :name ] }
    #   [ { "item" => { "id" => "one", "name" => "two" } } ]
    # )
    #
    def match_each(mapping, value, type=:each, root="")
      misses = []
      if mapping.is_a?(Array)
        misses = match_each_shallow(mapping, value)
      else
        value.each_with_index do |val, index|
          if !val.is_a?(Hash)
            misses << "Each check failed. #{val} is no hash at #{root}[#{index}]"
            break
          end

          mapping.each do |key, fields|
            key = key.to_s
            miss_key = root == "" ? key : "#{root}.#{key}"

            if !val[key]
              misses << "Each check failed. Key #{miss_key} is missing at #{root}[#{index}]"
            end

            if !val[key].is_a?(Hash)
              misses << "Each check failed. #{miss_key} is no hash at #{root}[#{index}]"
            end

            if fields.is_a?(Hash)
              match_each(fields,val[key],type,miss_key)
              next
            end

            fields.each do |attr|
              if !val[key].has_key?(attr.to_s)
                misses << "Each check failed. #{miss_key}[#{attr}] is missing at #{root}[#{index}]"
              end
            end
          end
        end
      end

      case type
      when :each
        @misses += misses.compact
      when :any
        if misses.compact.size == value.size
          @misses << "Shallow any check failed: #{misses}"
        end
      when :none
        if misses.compact.size != value.size
          @misses << "Shallow none check failed: #{misses}"
        end
      end
    end

    # Wrapper around #match_each
    #
    def match_any(fields, value)
      match_each(fields, value, :any)
    end

    # Wrapper around #match_each
    #
    def match_none(fields, value)
      match_each(fields, value, :none)
    end

    # Match each only for fields
    #
    # @param [Array<Symbol>] fields  list of required fields
    # @param [Array] list of objects that carry fields
    # @return [void]
    #
    def match_each_shallow(fields, value)
      misses = []
      value.each_with_index do |val, index|
        fields.each do |attr|
          if !val.has_key?(attr.to_s)
            misses[index] = "Shallow each check failed. Key #{attr} is missing at [#{index}]"
            break
          end
        end
      end

      return misses
    end

    # Match fields on a hash
    # @param [Hash,Array<Symbol>] fields  list of required fields
    # @param [Hash] value  Hash to check fields in
    # @return [void]
    #
    # @example Using array (each)
    # # every field must be present
    # spec = Jason.spec(fields: [ :id, :name ])
    # spec.fits({ 'id' => 1, 'name' => "jason" })
    # not spec.fits({ 'id' => 1 })
    #
    # @example Using each
    # # same as passing the array
    # spec = Jason.spec(fields: { each: [ :id, :name ] })
    # spec.fits({ 'id' => 1, 'name' => "jason" })
    # not spec.fits({ 'id' => 1 })
    #
    # @example Using any
    # spec = Jason.spec(fields: { any: [ :id, :name ] })
    # spec.fits({ 'id' => 1 })
    #
    # @example Using none
    # spec = Jason.spec(fields: { none: [ :id, :name ] })
    # not spec.fits({ 'id' => 1 })
    #
    def match_fields(fields, value, type=:each)
      if fields.is_a?(Hash)
        fields.each do |type, v_fields|
          match_fields(v_fields, value, type)
        end
        return
      end

      fields.map!(&:to_s)
      res = fields & value.keys

      case type
      when :each
        @misses << "Field(s) #{res - fields} are missing" if res.sort != fields.sort
      when :any
        @misses << "None of the fields #{fields} where found" if res.empty?
      when :none
        @misses << "Fields #{res} found, none of them where expected" if res.any?
      end
    end

  end
end
