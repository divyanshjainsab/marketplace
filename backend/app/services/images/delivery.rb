module Images
  module Delivery
    require "uri"

    THUMBNAIL_TRANSFORMATION = {
      width: 300,
      height: 300,
      crop: "fill",
      gravity: "auto",
      fetch_format: "auto",
      quality: "auto"
    }.freeze

    MEDIUM_TRANSFORMATION = {
      width: 800,
      crop: "limit",
      fetch_format: "auto",
      quality: "auto"
    }.freeze

    FULL_TRANSFORMATION = {
      fetch_format: "auto",
      quality: "auto"
    }.freeze

    VARIANTS = {
      thumbnail: THUMBNAIL_TRANSFORMATION,
      medium: MEDIUM_TRANSFORMATION,
      full: FULL_TRANSFORMATION
    }.freeze

    CLOUDINARY_HOST_PATTERN = /\Ares(?:-\d+)?\.cloudinary\.com\z/.freeze

    module_function

    def cloudinary_url?(url)
      uri = URI.parse(url.to_s)
      uri.is_a?(URI::HTTPS) && uri.host.to_s.match?(CLOUDINARY_HOST_PATTERN)
    rescue URI::InvalidURIError
      false
    end

    def url(public_id:, version:, variant: :full)
      return nil if public_id.blank? || version.blank?

      raw = Cloudinary::Utils.cloudinary_url(
        public_id.to_s,
        secure: true,
        version: version.to_i,
        transformation: VARIANTS.fetch(variant.to_sym).dup
      )

      raw.is_a?(Array) ? raw.first : raw
    rescue StandardError => e
      return nil if defined?(CloudinaryException) && e.is_a?(CloudinaryException)

      raise
    end

    def urls(public_id:, version:, optimized_url: nil)
      full_url = optimized_url.presence || url(public_id: public_id, version: version, variant: :full)
      {
        thumbnail: url(public_id: public_id, version: version, variant: :thumbnail),
        medium: url(public_id: public_id, version: version, variant: :medium),
        full: full_url
      }.compact
    end

    def asset(public_id:, version:, width:, height:, optimized_url: nil)
      return nil if public_id.blank? || version.blank?

      optimized_url ||= url(public_id: public_id, version: version, variant: :full)

      {
        public_id: public_id,
        optimized_url: optimized_url,
        version: version.to_i,
        width: width.to_i,
        height: height.to_i,
        urls: urls(public_id: public_id, version: version, optimized_url: optimized_url)
      }.compact
    end
  end
end
