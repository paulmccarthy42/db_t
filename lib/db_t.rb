require "db_t/railtie"

module DbT
  def self.with_t(record)
    presented_record = record ? ApplicationRecordPresenter.new(record) : nil
    if block_given?
      yield(presented_record)
    else
      return presented_record
    end
  end

  def self.default(record)
    presented_record = record ? ApplicationRecordPresenter.new(record, default: true) : nil
    if block_given?
      yield(presented_record)
    else
      return presented_record
    end
  end
end

require 'presenters/application_record_presenter.rb'