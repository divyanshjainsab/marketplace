module Images
  class ImageUploader
    UploadResult = Struct.new(:url, :public_id, keyword_init: true)

    def self.upload(io:, filename:, folder: nil, tags: nil)
      new.upload(io: io, filename: filename, folder: folder, tags: tags)
    end

    def self.attach(record:, io:, filename:, attribute: :image_url, folder: nil, delete_old: false)
      new.attach(record: record, io: io, filename: filename, attribute: attribute, folder: folder, delete_old: delete_old)
    end

    def self.delete_later(url:, wait: nil)
      new.delete_later(url: url, wait: wait)
    end

    def upload(io:, filename:, folder:, tags:)
      raise ArgumentError, "io is required" if io.nil?
      raise ArgumentError, "filename is required" if filename.blank?

      options = { resource_type: "image" }
      options[:folder] = folder if folder.present?
      options[:tags] = Array(tags) if tags.present?

      response = Cloudinary::Uploader.upload(io, { filename: filename }.merge(options))
      UploadResult.new(url: response["secure_url"] || response["url"], public_id: response["public_id"])
    end

    def attach(record:, io:, filename:, attribute:, folder:, delete_old:)
      raise ArgumentError, "record is required" if record.nil?

      old_url = record.public_send(attribute)
      result = upload(io: io, filename: filename, folder: folder, tags: record.class.name.underscore)

      record.update!(attribute => result.url)

      if delete_old && old_url.present? && old_url != result.url
        delete_later(url: old_url)
      end

      result
    end

    # Soft delete should not remove immediately, so deletion is always explicit.
    def delete_later(url:, wait: nil)
      public_id = CloudinaryPublicId.from_url(url)
      return nil if public_id.blank?

      job = Images::DeleteCloudinaryAssetJob
      if wait.present?
        job.set(wait: wait).perform_later(public_id)
      else
        job.perform_later(public_id)
      end
    end
  end
end
