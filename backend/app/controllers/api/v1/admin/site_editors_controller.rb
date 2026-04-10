module Api
  module V1
    module Admin
      class SiteEditorsController < BaseController
        def show
          config = Rails.cache.fetch(cache_key, expires_in: 60) do
            current_organization.homepage_config || {}
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
          sanitized = SiteEditor::HomepageConfigSanitizer.call(raw: raw)

          current_organization.update!(homepage_config: sanitized)
          Rails.cache.delete(cache_key)
          Rails.cache.delete("homepage_config:org:#{current_organization.id}")

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
      end
    end
  end
end
