module Images
  class ImageUploader
    MAX_FILE_SIZE = 15.megabytes
    ALLOWED_CONTENT_TYPES = %w[
      image/jpeg
      image/png
      image/webp
      image/avif
      image/gif
    ].freeze

    class InvalidUploadError < StandardError; end

    UploadResult = Struct.new(:asset, :url, :public_id, :version, :width, :height, keyword_init: true)

    def self.upload(io:, filename:, content_type: nil, folder: nil, tags: nil)
      new.upload(io: io, filename: filename, content_type: content_type, folder: folder, tags: tags)
    end

    def self.attach(record:, uploaded_file:, folder:, tags: nil, prefix: :image, delete_old: false, organization_id:, marketplace_id: nil, request_host: nil)
      Images::ImageAttachment.attach_upload(
        record: record,
        uploaded_file: uploaded_file,
        folder: folder,
        tags: tags,
        prefix: prefix,
        delete_old: delete_old,
        organization_id: organization_id,
        marketplace_id: marketplace_id,
        request_host: request_host
      )
    end

    def self.delete_later(url: nil, public_id: nil, wait: nil, organization_id:, marketplace_id: nil, request_host: nil)
      new.delete_later(
        url: url,
        public_id: public_id,
        wait: wait,
        organization_id: organization_id,
        marketplace_id: marketplace_id,
        request_host: request_host
      )
    end

    def upload(io:, filename:, content_type:, folder:, tags:)
      raise InvalidUploadError, "image file is required" if io.nil?
      raise InvalidUploadError, "filename is required" if filename.blank?

      validate_content_type!(content_type)
      validate_file_size!(io)

      options = { resource_type: "image" }
      options[:folder] = folder if folder.present?
      options[:tags] = Array(tags) if tags.present?

      response = Cloudinary::Uploader.upload(io, { filename: filename }.merge(options))
      asset = Images::Delivery.asset(
        public_id: response["public_id"],
        version: response["version"],
        width: response["width"],
        height: response["height"]
      )

      raise InvalidUploadError, "Cloudinary upload did not return a valid asset" if asset.nil?

      UploadResult.new(
        asset: asset,
        url: asset[:optimized_url],
        public_id: asset[:public_id],
        version: asset[:version],
        width: asset[:width],
        height: asset[:height]
      )
    rescue CloudinaryException => error
      raise InvalidUploadError, error.message
    rescue StandardError => error
      raise if error.is_a?(InvalidUploadError)

      raise InvalidUploadError, error.message.presence || "Unable to upload image"
    ensure
      rewind_io(io)
    end

    def delete_later(url: nil, public_id: nil, wait: nil, organization_id:, marketplace_id: nil, request_host: nil)
      public_id = public_id.presence || CloudinaryPublicId.from_url(url)
      return nil if public_id.blank?

      org_id = organization_id.to_i
      raise ArgumentError, "organization_id is required for tenant-isolated background jobs" if org_id <= 0

      context = {
        request_host: request_host,
        marketplace_id: marketplace_id
      }.compact

      job = Images::DeleteCloudinaryAssetJob
      if wait.present?
        job.set(wait: wait).perform_later(org_id, public_id, context)
      else
        job.perform_later(org_id, public_id, context)
      end
    end

    private

    def validate_content_type!(content_type)
      return if content_type.blank?
      return if ALLOWED_CONTENT_TYPES.include?(content_type)

      raise InvalidUploadError, "Unsupported image type"
    end

    def validate_file_size!(io)
      size =
        if io.respond_to?(:size)
          io.size
        elsif io.respond_to?(:path) && io.path.present?
          File.size(io.path)
        end

      return if size.nil? || size <= MAX_FILE_SIZE

      raise InvalidUploadError, "Image must be 15 MB or smaller"
    end

    def rewind_io(io)
      io.rewind if io.respond_to?(:rewind)
    rescue IOError
      nil
    end
  end
end
