module HasCloudinaryImage
  extend ActiveSupport::Concern

  included do
    validates :image_url, length: { maximum: 4096 }, allow_nil: true
    validates :image_public_id, length: { maximum: 512 }, allow_nil: true
    validates :image_version, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
    validates :image_width, :image_height, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true

    validate :cloudinary_image_fields_are_consistent
  end

  def image_asset
    Images::AssetPayload.from_record(self)
  end

  private

  def cloudinary_image_fields_are_consistent
    values = [image_url, image_public_id, image_version, image_width, image_height]
    return if values.compact.empty?

    if image_url.blank? || image_public_id.blank? || image_version.blank? || image_width.blank? || image_height.blank?
      errors.add(:base, "image metadata is incomplete")
      return
    end

    return if Images::Delivery.cloudinary_url?(image_url)

    errors.add(:image_url, "must use a Cloudinary delivery URL")
  end
end
