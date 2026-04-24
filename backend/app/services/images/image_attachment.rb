module Images
  class ImageAttachment
    def self.attach_upload(record:, uploaded_file:, folder:, tags: nil, prefix: :image, delete_old: false)
      new.attach_upload(
        record: record,
        uploaded_file: uploaded_file,
        folder: folder,
        tags: tags,
        prefix: prefix,
        delete_old: delete_old
      )
    end

    def self.replace(record:, asset_payload:, folder_prefix:, prefix: :image, delete_old: false)
      new.replace(
        record: record,
        asset_payload: asset_payload,
        folder_prefix: folder_prefix,
        prefix: prefix,
        delete_old: delete_old
      )
    end

    def self.clear(record:, prefix: :image, delete_old: false)
      new.clear(record: record, prefix: prefix, delete_old: delete_old)
    end

    def attach_upload(record:, uploaded_file:, folder:, tags:, prefix:, delete_old:)
      result = Images::ImageUploader.upload(
        io: uploaded_file.tempfile,
        filename: uploaded_file.original_filename,
        content_type: uploaded_file.content_type,
        folder: folder,
        tags: tags
      )

      replace(
        record: record,
        asset_payload: result.asset,
        folder_prefix: folder,
        prefix: prefix,
        delete_old: delete_old
      )
    end

    def replace(record:, asset_payload:, folder_prefix:, prefix:, delete_old:)
      asset = Images::AssetPayload.normalize!(payload: asset_payload, folder_prefix: folder_prefix)
      old_public_id = record.public_send("#{prefix}_public_id")

      record.update!(Images::AssetPayload.to_record_attributes(asset, prefix: prefix))

      if delete_old && old_public_id.present? && old_public_id != asset[:public_id]
        Images::ImageUploader.delete_later(public_id: old_public_id)
      end

      asset
    end

    def clear(record:, prefix:, delete_old:)
      old_public_id = record.public_send("#{prefix}_public_id")

      record.update!(
        "#{prefix}_url" => nil,
        "#{prefix}_public_id" => nil,
        "#{prefix}_version" => nil,
        "#{prefix}_width" => nil,
        "#{prefix}_height" => nil
      )

      Images::ImageUploader.delete_later(public_id: old_public_id) if delete_old && old_public_id.present?
    end
  end
end
