module Images
  class CloudinaryPublicId
    require "uri"

    # Best-effort extraction of Cloudinary public_id from a delivered asset URL.
    # Examples:
    # https://res.cloudinary.com/<cloud>/image/upload/v1234/folder/name.jpg
    # https://res.cloudinary.com/<cloud>/image/upload/folder/name.png
    def self.from_url(url)
      return nil if url.blank?

      uri = URI.parse(url.to_s)
      path = uri.path.to_s

      upload_index = path.index("/upload/")
      return nil unless upload_index

      remainder = path[(upload_index + "/upload/".length)..]
      remainder = remainder.sub(/\Av\d+\//, "") # optional version segment
      remainder = remainder.sub(/\A[a-z0-9_,-]+\/+/, "") if remainder.start_with?("c_", "q_", "w_", "h_", "f_")

      remainder = remainder.sub(/\.[^.\/]+\z/, "") # strip extension
      remainder.presence
    rescue URI::InvalidURIError
      nil
    end
  end
end
