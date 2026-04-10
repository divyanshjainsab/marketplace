require "uri"

module Auth
  class ReturnTo
    SESSION_KEY = :sso_redirect_target

    Target = Struct.new(:callback_url, :redirect_path, :state_url, keyword_init: true) do
      def present?
        callback_url.present?
      end
    end

    def self.store(session:, redirect_url:, state:, return_to: nil)
      target = new(redirect_url: redirect_url, state: state, return_to: return_to).sanitize
      session[SESSION_KEY] = target ? target.to_h.stringify_keys : nil
      target
    end

    def self.fetch(session:)
      payload = session[SESSION_KEY]
      return nil unless payload.is_a?(Hash)
      payload = payload.stringify_keys

      Target.new(
        callback_url: payload["callback_url"],
        redirect_path: payload["redirect_path"],
        state_url: payload["state_url"]
      )
    end

    def self.clear(session:)
      session.delete(SESSION_KEY)
    end

    def self.build_redirect(target:, token_pair:, fallback:)
      return fallback unless target&.present?

      uri = URI.parse(target.callback_url)
      params = Rack::Utils.parse_nested_query(uri.query)
      params["token"] = token_pair.access_token
      params["refresh_token"] = token_pair.refresh_token
      params["exp"] = token_pair.access_exp.to_i.to_s
      params["refresh_exp"] = token_pair.refresh_exp.to_i.to_s
      if target.redirect_path.present?
        params["return_to"] = target.redirect_path
        params["redirect"] ||= target.redirect_path
      end
      uri.query = params.to_query
      uri.to_s
    rescue URI::InvalidURIError
      fallback
    end

    def initialize(redirect_url:, state:, return_to:)
      @redirect_url = redirect_url.to_s
      @state = state.to_s
      @return_to = return_to.to_s
    end

    def sanitize
      target_from_callback_and_path || target_from_state || target_from_redirect || target_from_return_to
    end

    private

    attr_reader :redirect_url, :state, :return_to

    def target_from_callback_and_path
      callback_uri = parse_http_url(redirect_url)
      return nil if callback_uri.nil?
      return nil unless allowed_host?(callback_uri)

      state_uri = parse_http_url(state)
      state_uri = nil unless state_uri.nil? || allowed_host?(state_uri)

      redirect_path = sanitize_return_path(return_to)
      redirect_path ||= redirect_path_for(state_uri) if state_uri.present?

      Target.new(
        callback_url: callback_uri.to_s,
        redirect_path: redirect_path,
        state_url: state_uri&.to_s
      )
    end

    def target_from_state
      return nil if state.blank?

      state_uri = parse_http_url(state)
      return nil if state_uri.nil?
      return nil unless allowed_host?(state_uri)

      callback_uri = callback_uri_for(state_uri)
      return nil if callback_uri.nil?

      Target.new(
        callback_url: callback_uri.to_s,
        redirect_path: redirect_path_for(state_uri),
        state_url: state_uri.to_s
      )
    end

    def target_from_redirect
      uri = parse_http_url(redirect_url)
      return nil if uri.nil?
      return nil unless allowed_host?(uri)

      Target.new(callback_url: uri.to_s, redirect_path: nil, state_url: nil)
    end

    def target_from_return_to
      uri = parse_http_url(return_to)
      return nil if uri.nil?
      return nil unless allowed_host?(uri)

      Target.new(callback_url: uri.to_s, redirect_path: nil, state_url: nil)
    end

    def callback_uri_for(state_uri)
      return URI.join("#{state_uri.scheme}://#{host_with_port(state_uri)}", normalized_callback_path) if normalized_callback_path.present?

      parse_http_url(redirect_url)
    rescue URI::InvalidURIError
      nil
    end

    def normalized_callback_path
      return nil if redirect_url.blank?
      return redirect_url if redirect_url.start_with?("/")

      uri = URI.parse(redirect_url)
      return nil unless uri.path.present?

      [uri.path, uri.query.present? ? "?#{uri.query}" : nil].compact.join
    rescue URI::InvalidURIError
      nil
    end

    def redirect_path_for(uri)
      path = uri.path.presence || "/"
      query = uri.query.present? ? "?#{uri.query}" : nil
      [path, query].compact.join
    end

    def parse_http_url(raw)
      return nil if raw.blank?

      uri = URI.parse(raw)
      return nil unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)

      uri
    rescue URI::InvalidURIError
      nil
    end

    def allowed_host?(uri)
      host = host_with_port(uri)

      allowed_hosts.any? do |pattern|
        if pattern.start_with?(".")
          uri.host == pattern.delete_prefix(".") || uri.host.end_with?(pattern)
        else
          host == pattern || uri.host == pattern
        end
      end
    end

    def allowed_hosts
      ENV.fetch("SSO_ALLOWED_REDIRECT_HOSTS", "localhost:3000,localhost:3001")
        .split(",")
        .map(&:strip)
        .reject(&:blank?)
    end

    def host_with_port(uri)
      port = uri.port
      default_port = uri.is_a?(URI::HTTPS) ? 443 : 80
      return uri.host if port == default_port

      "#{uri.host}:#{port}"
    end

    def sanitize_return_path(raw)
      value = raw.to_s.strip
      return nil if value.blank?
      return nil unless value.start_with?("/")
      return nil if value.start_with?("//")

      value
    end
  end
end
