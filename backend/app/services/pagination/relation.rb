module Pagination
  class Relation
    DEFAULT_PAGE = 1
    DEFAULT_PER_PAGE = 20
    MAX_PER_PAGE = 100

    def self.per_page_value(raw)
      value = raw.to_i
      return DEFAULT_PER_PAGE if value <= 0

      [value, MAX_PER_PAGE].min
    end

    def initialize(scope, page:, per_page:)
      @scope = scope
      @page = [page.to_i, DEFAULT_PAGE].max
      @per_page = self.class.per_page_value(per_page)
    end

    def call
      scope.limit(per_page).offset((page - 1) * per_page)
    end

    def meta
      total_count = scope.except(:limit, :offset, :order).count(:all)
      total_pages = (total_count / per_page.to_f).ceil

      {
        page: page,
        per_page: per_page,
        total_count: total_count,
        total_pages: [total_pages, 1].max
      }
    end

    private

    attr_reader :scope, :page, :per_page
  end
end
