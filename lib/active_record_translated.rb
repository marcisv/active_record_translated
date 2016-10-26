require 'active_record_translated/translated'
require 'active_record_translated/translation'

module ActiveRecordTranslated
  cattr_writer :mandatory_locales

  def self.mandatory_locales
    @@mandatory_locales || I18n.available_locales
  end

  def self.include_in_base
    ActiveRecord::Base.send(:include, ActiveRecordTranslated::Translated)
  end
end

if defined?(Rails)
  require 'active_record_translated/railtie'
elsif defined?(ActiveRecord)
  ActiveRecordTranslated.include_in_base
end
