class ImageAssetSerializer < BaseSerializer
  def as_json
    return nil if record.blank?

    {
      public_id: record[:public_id],
      optimized_url: record[:optimized_url],
      version: record[:version],
      width: record[:width],
      height: record[:height],
      urls: record[:urls]
    }.compact
  end
end
