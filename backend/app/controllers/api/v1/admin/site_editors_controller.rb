module Api
  module V1
    module Admin
      class SiteEditorsController < BaseController
        before_action do
          require_admin_permission!("manage_marketplace")
        end

        def show
          config = Rails.cache.fetch(cache_key, expires_in: 60) do
            SiteEditor::HomepageConfigSanitizer.call(
              raw: current_organization.homepage_config || {},
              organization: current_organization
            )
          end

          render json: {
            data: {
              organization: OrganizationSerializer.one(current_organization),
              homepage_config: config
            }
          }
        end

        def update
          raw = params.require(:homepage_config)
          previous_public_ids = media_public_ids(current_organization.homepage_config)
          sanitized = SiteEditor::HomepageConfigSanitizer.call(raw: raw, organization: current_organization)

          current_organization.update!(homepage_config: sanitized)
          Rails.cache.delete(cache_key)
          Rails.cache.delete("homepage_config:org:#{current_organization.id}")
          delete_removed_media_assets(previous_public_ids, media_public_ids(sanitized))

          render json: {
            data: {
              organization: OrganizationSerializer.one(current_organization),
              homepage_config: sanitized
            }
          }
        end

        private

        def cache_key
          "admin:site_editor:org:#{current_organization.id}"
        end

        def media_public_ids(config)
          config = config.to_h if config.respond_to?(:to_h)
          return [] unless config.is_a?(Hash)

          ids = []
          hero_image = normalize_media_hash(config.dig("hero_banner", "image") || config.dig(:hero_banner, :image))
          ids << hero_image["public_id"] if hero_image["public_id"].present?

          promo_blocks = config["promotional_blocks"] || config[:promotional_blocks]
          Array(promo_blocks).each do |block|
            next unless block.is_a?(Hash)

            image = normalize_media_hash(block["image"] || block[:image])
            ids << image["public_id"] if image["public_id"].present?
          end

          ids.compact.uniq
        end

        def delete_removed_media_assets(previous_public_ids, current_public_ids)
          (previous_public_ids - current_public_ids).each do |public_id|
            Images::ImageUploader.delete_later(public_id: public_id)
          end
        end

        def normalize_media_hash(value)
          hash =
            if value.respond_to?(:to_h)
              value.to_h
            elsif value.is_a?(Hash)
              value
            else
              {}
            end

          hash.with_indifferent_access
        end
      end
    end
  end
end
