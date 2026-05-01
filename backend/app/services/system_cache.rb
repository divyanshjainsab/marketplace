# frozen_string_literal: true

module SystemCache
  SYSTEM_PREFIX = "system"

  def self.fetch(namespace:, key:, **options, &block)
    Rails.cache.fetch(build_key(namespace: namespace, key: key), **options, &block)
  end

  def self.read(namespace:, key:)
    Rails.cache.read(build_key(namespace: namespace, key: key))
  end

  def self.write(namespace:, key:, value:, **options)
    Rails.cache.write(build_key(namespace: namespace, key: key), value, **options)
  end

  def self.delete(namespace:, key:)
    Rails.cache.delete(build_key(namespace: namespace, key: key))
  end

  def self.build_key(namespace:, key:)
    ns = normalize_segment(namespace, label: "namespace")
    k = normalize_segment(key, label: "key")
    "#{SYSTEM_PREFIX}:#{ns}:#{k}"
  end

  def self.normalize_segment(value, label:)
    segment = value.to_s
    raise ArgumentError, "#{label} is required" if segment.blank?

    segment.gsub(" ", "_")
  end

  private_class_method :normalize_segment
end

