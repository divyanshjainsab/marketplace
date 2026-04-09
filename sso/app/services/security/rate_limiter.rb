module Security
  class RateLimiter
    Result = Struct.new(:allowed?, :retry_after, keyword_init: true)

    def self.check(key:, limit:, period:)
      new(key: key, limit: limit, period: period).check
    end

    def initialize(key:, limit:, period:)
      @key = key
      @limit = limit
      @period = period
      @cache = Rails.cache
    end

    def check
      now = Time.current.to_i
      bucket = (now / @period).floor
      cache_key = "rate-limit:#{@key}:#{bucket}"
      count = @cache.increment(cache_key, 1, expires_in: @period)
      if count.nil?
        @cache.write(cache_key, 1, expires_in: @period)
        count = 1
      end

      if count > @limit
        retry_after = @period - (now % @period)
        return Result.new(allowed?: false, retry_after: retry_after)
      end

      Result.new(allowed?: true, retry_after: nil)
    end
  end
end
