module Images
  class FolderPath
    TARGETS = %i[product variant listing site_editor].freeze

    def self.for(target:, organization:, marketplace: nil)
      new(target: target, organization: organization, marketplace: marketplace).path
    end

    def self.tags(target:, organization:, marketplace: nil)
      [
        "org:#{organization.id}",
        "target:#{target}",
        (marketplace ? "marketplace:#{marketplace.id}" : nil)
      ].compact
    end

    def initialize(target:, organization:, marketplace:)
      @target = target.to_sym
      @organization = organization
      @marketplace = marketplace
    end

    def path
      raise ArgumentError, "unsupported media target" unless TARGETS.include?(@target)

      segments = ["marketplace", "org-#{@organization.id}-#{slug_segment(@organization.slug)}"]
      if @target == :listing
        raise ArgumentError, "marketplace is required for listing uploads" if @marketplace.nil?

        segments << "marketplace-#{@marketplace.id}-#{slug_segment(@marketplace.name)}"
      end

      segments << target_segment
      segments.join("/")
    end

    private

    def slug_segment(value)
      value.to_s.parameterize.presence || "default"
    end

    def target_segment
      case @target
      when :product then "products"
      when :variant then "variants"
      when :listing then "listings"
      when :site_editor then "site-editor"
      else
        @target.to_s.dasherize
      end
    end
  end
end
