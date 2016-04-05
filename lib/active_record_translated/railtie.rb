class ActiveRecordTranslated::Railtie < Rails::Railtie
  initializer 'active_record_translated.include_in_base' do
    ActiveRecordTranslated.include_in_base
  end

  generators do
    require 'active_record_translated/translation_generator'
  end
end
