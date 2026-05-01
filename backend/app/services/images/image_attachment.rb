module Images
  class ImageAttachment
    def self.attach_upload(record:, uploaded_file:, folder:, tags: nil, prefix: :image, delete_old: false, organization_id:, marketplace_id: nil, request_host: nil)
      new.attach_upload(
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

    def self.replace(record:, asset_payload:, folder_prefix:, prefix: :image, delete_old: false, organization_id:, marketplace_id: nil, request_host: nil)
      new.replace(
        record: record,
        asset_payload: asset_payload,
        folder_prefix: folder_prefix,
        prefix: prefix,
        delete_old: delete_old,
        organization_id: organization_id,
        marketplace_id: marketplace_id,
        request_host: request_host
      )
    end

    def self.clear(record:, prefix: :image, delete_old: false, organization_id:, marketplace_id: nil, request_host: nil)
      new.clear(
        record: record,
        prefix: prefix,
        delete_old: delete_old,
        organization_id: organization_id,
        marketplace_id: marketplace_id,
        request_host: request_host
      )
    end

    def attach_upload(record:, uploaded_file:, folder:, tags:, prefix:, delete_old:, organization_id:, marketplace_id:, request_host:)
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
        delete_old: delete_old,
        organization_id: organization_id,
        marketplace_id: marketplace_id,
        request_host: request_host
      )
    end

    def replace(record:, asset_payload:, folder_prefix:, prefix:, delete_old:, organization_id:, marketplace_id:, request_host:)
      asset = Images::AssetPayload.normalize!(payload: asset_payload, folder_prefix: folder_prefix)
      old_public_id = record.public_send("#{prefix}_public_id")

      record.update!(Images::AssetPayload.to_record_attributes(asset, prefix: prefix))

      if delete_old && old_public_id.present? && old_public_id != asset[:public_id]
        Images::ImageUploader.delete_later(
          public_id: old_public_id,
          organization_id: organization_id,
          marketplace_id: marketplace_id,
          request_host: request_host
        )
      end

      asset
    end

    def clear(record:, prefix:, delete_old:, organization_id:, marketplace_id:, request_host:)
      old_public_id = record.public_send("#{prefix}_public_id")

      record.update!(
        "#{prefix}_url" => nil,
        "#{prefix}_public_id" => nil,
        "#{prefix}_version" => nil,
        "#{prefix}_width" => nil,
        "#{prefix}_height" => nil
      )

      if delete_old && old_public_id.present?
        Images::ImageUploader.delete_later(
          public_id: old_public_id,
          organization_id: organization_id,
          marketplace_id: marketplace_id,
          request_host: request_host
        )
      end
    end
  end
end
