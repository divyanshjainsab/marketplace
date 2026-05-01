module Images
  class DeleteCloudinaryAssetJob < TenantJob
    queue_as :low

    def perform(_organization_id, public_id, _context = {})
      return if public_id.blank?

      Cloudinary::Uploader.destroy(public_id.to_s, resource_type: "image", invalidate: true)
    end
  end
end
