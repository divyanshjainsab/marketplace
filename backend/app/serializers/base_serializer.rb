class BaseSerializer
  def self.one(record, context: {})
    new(record, context: context).as_json
  end

  def self.many(records, context: {})
    records.map { |record| one(record, context: context) }
  end

  def initialize(record, context: {})
    @record = record
    @context = context
  end

  private

  attr_reader :record, :context
end
