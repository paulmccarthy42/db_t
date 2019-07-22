class ApplicationRecordPresenter < SimpleDelegator
  def delegated
    __getobj__
  end

  def initialize(record, options = {})
    super(record)
    @record = record
    @options = options
    @nearest_translated_ancestor = find_nearest_translated_ancestor
    load_translations
  end

  def translated_fields
    translation_manifest[@nearest_translated_ancestor] || []
  end

  def valid_keys_for(field)
    I18n.t("active_record.#{@nearest_translated_ancestor}.#{field}", raise: true).keys.map(&:to_s)
  rescue
    []
  end

  private

  def load_translations
    translated_fields.each do |column|
      (class << self; self; end).class_eval do
        define_method column do
          db_t(column, @options)
        end
      end
    end
  end

  def db_t(field_name, options = {})
    begin
      result = @record.public_send("#{field_name}_slug".to_sym)
      return unless result

      I18n.with_locale(options[:default] ? I18n.default_locale : I18n.locale) do
          I18n.t("active_record.#{@nearest_translated_ancestor}.#{field_name}.#{result}", raise: true)
      end
    rescue
      @record.send(field_name)
    end
  end

  # pulls a list of models and their translated columns
  def translation_manifest
    I18n.with_locale(I18n.default_locale) do
      manifest_with_copy = I18n.t("active_record", raise: true)
      manifest_with_copy.transform_values {|columns| columns.keys }
    end
  end

  # returns (in slug form) the nearest ancestor class that has translations stored in I18n
  def find_nearest_translated_ancestor
    class_name(
    @record
      .class
      .ancestors
      .find { |a| translation_manifest.keys.include?(class_name(a)) }
    )
  end

  def class_name(record)
    record&.name&.underscore&.to_sym
  end
end
