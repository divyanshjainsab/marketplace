module Api
  module V1
    module Admin
      class MediaAssetsController < BaseController
        TARGET_PERMISSION = {
          "product" => "edit_listings",
          "variant" => "edit_listings",
          "listing" => "edit_listings",
          "site_editor" => "manage_marketplace"
        }.freeze

        before_action :require_media_permission!

        def create
          file = params[:file] || params[:image]
          return render_error("bad_request", status: :bad_request, message: "Image file is required") if file.blank?

          result = Images::ImageUploader.upload(
            io: file.tempfile,
            filename: file.original_filename,
            content_type: file.content_type,
            folder: upload_folder,
            tags: Images::FolderPath.tags(target: media_target, organization: current_organization, marketplace: media_marketplace)
          )

          response.headers["Cache-Control"] = "no-store"

          render json: {
            data: result.asset
          }, status: :created
        rescue Images::ImageUploader::InvalidUploadError, Images::AssetPayload::InvalidAssetError, ArgumentError => error
          render_error("validation_failed", status: :unprocessable_entity, message: error.message)
        end

        private

        def media_target
          @media_target ||= params[:target].to_s
        end

        def media_marketplace
          media_target == "listing" ? current_marketplace : nil
        end

        def upload_folder
          Images::FolderPath.for(
            target: media_target,
            organization: current_organization,
            marketplace: media_marketplace
          )
        end

        def require_media_permission!
          permission = TARGET_PERMISSION[media_target]
          return render_error("bad_request", status: :bad_request, message: "Unsupported media target") if permission.nil?

          require_admin_permission!(permission)
        end
      end
    end
  end
end
