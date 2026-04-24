module TenantDomain
  def self.from_request(request)
    origin = RequestOrigin.extract(request)
    normalize(host: origin.host, port: origin.port, scheme: origin.scheme)
  end

  def self.normalize(host:, port:, scheme: nil)
    normalized_host = host.to_s.strip.downcase
    normalized_host = "localhost" if %w[127.0.0.1 0.0.0.0].include?(normalized_host)
    return "" if normalized_host.blank?

    normalized_port = port.to_i
    return normalized_host if normalized_port <= 0

    # Tenant IDs should not depend on scheme; omit the common default ports to keep
    # `custom_domain` stable across HTTP->HTTPS redirects and proxy termination.
    return normalized_host if normalized_port == 80 || normalized_port == 443

    "#{normalized_host}:#{normalized_port}"
  end
end

