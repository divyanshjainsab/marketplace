module Images
  class AssetPayload
    class InvalidAssetError < StandardError; end

    CORE_KEYS = %i[public_id optimized_url version width height].freeze

    def self.normalize(payload:, folder_prefix: nil)
      new(payload: payload, folder_prefix: folder_prefix).normalize
    end

    def self.normalize!(payload:, folder_prefix: nil)
      new(payload: payload, folder_prefix: folder_prefix).normalize!
    end

    def self.from_record(record, prefix: :image)
      public_id = record.public_send("#{prefix}_public_id")
      version = record.public_send("#{prefix}_version")
      optimized_url = record.public_send("#{prefix}_url")
      width = record.public_send("#{prefix}_width")
      height = record.public_send("#{prefix}_height")

      return nil if public_id.blank? || version.blank? || optimized_url.blank?

      Delivery.asset(
        public_id: public_id,
        version: version,
        optimized_url: optimized_url,
        width: width,
        height: height
      )
    end

    def self.to_record_attributes(payload, prefix: :image)
      asset = payload.respond_to?(:slice) ? payload.slice(*CORE_KEYS) : {}
      {
        "#{prefix}_url" => asset[:optimized_url],
        "#{prefix}_public_id" => asset[:public_id],
        "#{prefix}_version" => asset[:version],
        "#{prefix}_width" => asset[:width],
        "#{prefix}_height" => asset[:height]
      }
    end

    def initialize(payload:, folder_prefix:)
      @payload = payload
      @folder_prefix = folder_prefix.to_s.strip.presence
    end

    def normalize
      hash = normalize_hash(@payload)
      return nil if hash.empty?

      public_id = hash[:public_id].to_s.strip
      optimized_url = hash[:optimized_url].to_s.strip
      version = hash[:version].to_i
      width = hash[:width].to_i
      height = hash[:height].to_i

      return nil if public_id.blank? || optimized_url.blank? || version <= 0 || width <= 0 || height <= 0
      return nil unless Images::Delivery.cloudinary_url?(optimized_url)
      return nil if @folder_prefix.present? && !public_id.start_with?("#{@folder_prefix}/")

      expected_url = Images::Delivery.url(public_id: public_id, version: version, variant: :full)
      return nil if expected_url != optimized_url

      {
        public_id: public_id,
        optimized_url: optimized_url,
        version: version,
        width: width,
        height: height
      }
    end

    def normalize!
      normalize || raise(InvalidAssetError, "Image asset is invalid")
    end

    private

    def normalize_hash(value)
      value = value.to_unsafe_h if value.respond_to?(:to_unsafe_h)
      return {} unless value.is_a?(Hash)

      value.deep_symbolize_keys
    end
  end
end
