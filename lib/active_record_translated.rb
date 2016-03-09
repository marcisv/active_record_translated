require 'active_record_translated/translated'
require 'active_record_translated/translation'

module ActiveRecordTranslated
  def self.include_in_base
    ActiveRecord::Base.send(:include, ActiveRecordTranslated::Translated)
  end
end

if defined?(Rails)
  require 'active_record_translated/railtie'
elsif defined?(ActiveRecord)
  ActiveRecordTranslated.include_in_base
end
