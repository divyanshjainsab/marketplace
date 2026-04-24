require "uri"

module RequestOrigin
  Result = Struct.new(:host, :port, :scheme, keyword_init: true)

  def self.extract(request)
    host = request.host.to_s
    port = request.port
    scheme = request.scheme.to_s

    return Result.new(host: host, port: port, scheme: scheme) unless trust_forwarded_headers?(request)

    forwarded_host = first_forwarded_host(request)
    forwarded_port = request.get_header("HTTP_X_FORWARDED_PORT").to_s
    forwarded_proto = request.get_header("HTTP_X_FORWARDED_PROTO").to_s

    if forwarded_host.present?
      parsed_host, parsed_port = split_host_port(forwarded_host)
      host = parsed_host if parsed_host.present?
      # If the proxy forwarded a host but omitted a port, prefer X-Forwarded-Port (or nil)
      # over the internal container port (e.g. 3000).
      port = parsed_port
    end

    if forwarded_port.present?
      forwarded_port_i = Integer(forwarded_port, 10) rescue nil
      port = forwarded_port_i if forwarded_port_i
    end

    scheme = forwarded_proto if forwarded_proto.present?

    Result.new(host: host, port: port, scheme: scheme)
  end

  def self.trust_forwarded_headers?(request)
    ActiveModel::Type::Boolean.new.cast(ENV.fetch("BACKEND_TRUST_FORWARDED_HOST"))
  end
  private_class_method :trust_forwarded_headers?

  def self.first_forwarded_host(request)
    forwarded = request.get_header("HTTP_FORWARDED").to_s
    if forwarded.present?
      host = forwarded.split(",").first.to_s
      host = host.split(";").find { |part| part.strip.start_with?("host=") }
      if host
        value = host.split("=", 2).last.to_s.strip
        value = value.delete_prefix("\"").delete_suffix("\"")
        return value if value.present?
      end
    end

    request.get_header("HTTP_X_FORWARDED_HOST").to_s.split(",").first.to_s.strip
  end
  private_class_method :first_forwarded_host

  def self.split_host_port(value)
    raw = value.to_s.strip
    return [raw, nil] if raw.empty?

    if raw.start_with?("[") # IPv6
      if (idx = raw.index("]"))
        host = raw[0..idx]
        rest = raw[(idx + 1)..]
        if rest&.start_with?(":")
          port = Integer(rest.delete_prefix(":"), 10) rescue nil
          return [host, port]
        end
        return [host, nil]
      end
    end

    host, port = raw.split(":", 2)
    return [raw, nil] if port.blank?

    [host, (Integer(port, 10) rescue nil)]
  end
  private_class_method :split_host_port
end
