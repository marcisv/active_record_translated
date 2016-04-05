require 'rails/generators'
module ActiveRecordTranslated
  class Error < Thor::Error
  end

  class TranslationGenerator < Rails::Generators::Base
    attr_accessor :error_message

    desc 'Generate a translation for model. Pass translateable model name and translateable attributes like you would do in rails model generator.'

    def generate_translation
      validate_translateable_model!
      validate_translation_model_name!
      validate_translateable_column_properties!

      colum_properties = ["#{translateable_model_name.underscore}:references", "locale:string"] + translateable_column_properties
      Rails::Generators.invoke('active_record:model', [translation_model_name, colum_properties])
      gsub_file translation_model_path, "belongs_to :#{translateable_model_name.underscore}", 'include ActiveRecordTranslated::Translation'
    end

    def alter_translateable_model
      inject_into_file translateable_model_path, after: /^class #{translateable_model_name}.*/ do
        "\n  translate #{translateable_column_properties.map{|properties| ":#{properties.split(':')[0]}" }.join('')}\n"
      end
    end

    private

    def translateable_model_name
      unless defined? @translateable_model_name
        @translateable_model_name = args[0] ? args[0].classify : nil
      end
      @translateable_model_name
    end

    def translateable_model
      @translateable_model ||= translateable_model_name.constantize
    end

    def translateable_model_path
      "app/models/#{translateable_model_name.underscore}.rb"
    end

    def translation_model_name
      @translation_model_name ||= "#{translateable_model_name}Translation"
    end

    def translation_model_path
      "app/models/#{translation_model_name.underscore}.rb"
    end

    def translateable_column_properties
      @translateable_column_properties ||= args[1..-1]
    end

    def translateable_model_missing?
      existing_model_names.exclude?(translateable_model_name)
    end

    def validate_translateable_model!
      if translateable_model_name.nil?
        raise Error, 'No model name given'
      elsif translateable_model_missing?
        raise Error, "Model #{translateable_model_name} does not exist"
      end
    end

    def validate_translateable_column_properties!
      if translateable_column_properties.empty?
        raise Error, 'No translateable column names provided'
      end
    end

    def validate_translation_model_name!
      if existing_model_names.include?(translation_model_name)
        raise Error, "Model #{translation_model_name} already exists"
      end
    end

    def existing_model_names
      unless defined? @existing_model_names
        Rails.application.eager_load!
        @existing_model_names = ActiveRecord::Base.subclasses.map(&:name)
      end
      @existing_model_names
    end

  end
end
