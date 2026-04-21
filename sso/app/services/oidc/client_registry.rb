require "json"

module Oidc
  class ClientRegistry
    Client = Struct.new(:client_id, :client_secret, :redirect_uris, keyword_init: true) do
      def confidential?
        client_secret.to_s.present?
      end
    end

    def self.fetch!(client_id)
      new.fetch!(client_id)
    end

    def initialize
      @clients = load_clients
    end

    def fetch!(client_id)
      client_id = client_id.to_s
      client = @clients[client_id]
      raise Errors::InvalidClient, "unknown_client" if client.nil?
      client
    end

    private

    def load_clients
      from_json = ENV["SSO_OIDC_CLIENTS_JSON"].to_s.presence
      if from_json
        parsed = JSON.parse(from_json)
        return parsed.each_with_object({}) do |entry, acc|
          next unless entry.is_a?(Hash)
          id = entry["client_id"].to_s
          next if id.blank?
          acc[id] = Client.new(
            client_id: id,
            client_secret: entry["client_secret"].to_s.presence,
            redirect_uris: Array(entry["redirect_uris"] || []).map(&:to_s).reject(&:blank?)
          )
        end
      end

      # Development defaults (override via env).
      backend_base = ENV.fetch("BACKEND_PUBLIC_BASE_URL").delete_suffix("/")
      {
        "adminfront" => Client.new(
          client_id: "adminfront",
          client_secret: ENV.fetch("SSO_OIDC_ADMINFRONT_CLIENT_SECRET"),
          redirect_uris: [
            "#{backend_base}/auth/oidc/callback/admin"
          ]
        ),
        "clientfront" => Client.new(
          client_id: "clientfront",
          client_secret: ENV.fetch("SSO_OIDC_CLIENTFRONT_CLIENT_SECRET"),
          redirect_uris: [
            "#{backend_base}/auth/oidc/callback/clientfront"
          ]
        )
      }
    rescue JSON::ParserError
      {}
    end
  end
end
