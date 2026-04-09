module Images
  class DeleteCloudinaryAssetJob < ApplicationJob
    queue_as :low

    def perform(public_id)
      return if public_id.blank?

      Cloudinary::Uploader.destroy(public_id.to_s, resource_type: "image", invalidate: true)
    end
  end
end
