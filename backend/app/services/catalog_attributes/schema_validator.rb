module CatalogAttributes
  class SchemaValidator
    KEY_FORMAT = /\A[a-z][a-z0-9_]*\z/.freeze

    def self.validate(values:, schema:, errors:, field:)
      new(values: values, schema: schema, errors: errors, field: field).validate
    end

    def initialize(values:, schema:, errors:, field:)
      @values = values
      @schema = Array(schema)
      @errors = errors
      @field = field
    end

    def validate
      unless @values.is_a?(Hash)
        @errors.add(@field, "must be an object")
        return
      end

      validate_key_format
      validate_against_schema if @schema.any?
    end

    private

    def validate_key_format
      @values.keys.each do |key|
        key_string = key.to_s
        next if key_string.match?(KEY_FORMAT)

        @errors.add(@field, "contains invalid attribute key '#{key_string}'")
      end
    end

    def validate_against_schema
      allowed = {}
      @schema.each do |entry|
        code = entry.catalog_attribute&.code
        next if code.blank?

        allowed[code] = entry
      end

      @values.each_key do |key|
        next if allowed.key?(key.to_s)

        @errors.add(@field, "contains unknown attribute '#{key}'")
      end

      allowed.each do |code, entry|
        next unless entry.required?
        next if value_present?(@values[code])

        @errors.add(@field, "is missing required attribute '#{code}'")
      end

      @values.each do |code, value|
        entry = allowed[code.to_s]
        next if entry.blank? # unknown already reported

        validate_value(code.to_s, value, entry)
      end
    end

    def validate_value(code, value, entry)
      return if value.nil?

      data_type = entry.catalog_attribute&.data_type.to_s
      config = entry.config.is_a?(Hash) ? entry.config : {}

      case data_type
      when "string", "enum"
        validate_string(code, value, config)
      when "integer"
        validate_integer(code, value, config)
      when "decimal"
        validate_decimal(code, value, config)
      when "boolean"
        validate_boolean(code, value)
      when "json"
        validate_json(code, value)
      when "array"
        validate_array(code, value)
      else
        @errors.add(@field, "has unsupported data_type '#{data_type}' for '#{code}'")
      end
    end

    def validate_string(code, value, config)
      unless value.is_a?(String)
        @errors.add(@field, "attribute '#{code}' must be a string")
        return
      end

      allowed_values = config["allowed_values"]
      return if allowed_values.blank?

      allowed = Array(allowed_values).map(&:to_s)
      return if allowed.include?(value)

      @errors.add(@field, "attribute '#{code}' must be one of: #{allowed.join(', ')}")
    end

    def validate_integer(code, value, config)
      unless value.is_a?(Integer)
        @errors.add(@field, "attribute '#{code}' must be an integer")
        return
      end

      allowed_values = config["allowed_values"]
      return if allowed_values.blank?

      allowed = Array(allowed_values).filter_map { |v| Integer(v) rescue nil }
      return if allowed.include?(value)

      @errors.add(@field, "attribute '#{code}' must be one of: #{allowed.join(', ')}")
    end

    def validate_decimal(code, value, _config)
      return if value.is_a?(Numeric)

      if value.is_a?(String)
        normalized = value.strip
        return if normalized.match?(/\A-?\d+(\.\d+)?\z/)
      end

      @errors.add(@field, "attribute '#{code}' must be a number")
    end

    def validate_boolean(code, value)
      return if value == true || value == false

      @errors.add(@field, "attribute '#{code}' must be a boolean")
    end

    def validate_json(code, value)
      return if value.is_a?(Hash)

      @errors.add(@field, "attribute '#{code}' must be an object")
    end

    def validate_array(code, value)
      return if value.is_a?(Array)

      @errors.add(@field, "attribute '#{code}' must be an array")
    end

    def value_present?(value)
      case value
      when nil
        false
      when String
        value.strip.present?
      when Array, Hash
        value.present?
      else
        true
      end
    end
  end
end

