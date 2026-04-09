module SoftDeletable
  extend ActiveSupport::Concern

  included do
    include Discard::Model
  end
end
