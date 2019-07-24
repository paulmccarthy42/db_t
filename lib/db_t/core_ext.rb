ActiveRecord::Base.class_eval do
  Error = Class.new(StandardError)
  TranslatorRequired = Class.new(Error)

  def self.translates(*columns)
    columns.each do |column|
      define_method(column) do |*args|
        super(*args)
      end

      define_method("#{column}_slug") do
        self[column]&.underscore&.gsub(%r{[ \/]}, '_')
      end

      private column
    end
  end

  def method_missing(name, *args, &block)
    return super unless DbT.default(self, &:translated_fields).include?(name)
    message = "#{name} is a translated field for #{self.class} - please wrap in DbT.with_t"
    if Rails.env.production?
      Rollbar.error(message)
      send(name)
    else
      fail TranslatorRequired, message
    end
  end
end