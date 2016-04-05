module ActiveRecordTranslated
  module Translated

    extend ActiveSupport::Concern

    included do
      def self.translate(*attribute_names)
        has_many :translations, -> { order(locale: :desc) }, {
          class_name: translation_class_name,
          dependent:  :destroy,
          inverse_of: self.name.underscore.to_sym
        }

        accepts_nested_attributes_for :translations, limit: -> { I18n.available_locales.count }

        scope :order_by_translation, -> field_name {
          joined_table_name = "#{I18n.locale}_translations"

          joins(
            <<-SQL
              LEFT JOIN #{translation_class.table_name} AS #{joined_table_name}
              ON #{table_name}.id = #{joined_table_name}.#{self.name.underscore}_id AND #{joined_table_name}.locale='#{I18n.locale}'
            SQL
          ).order("#{joined_table_name}.#{field_name}")
        }

        validate :translations_presence

        attribute_names.each do |attribute_name|
          define_method attribute_name do |*args|
            raise ArgumentError if args.count > 1
            locale = args[0] || I18n.locale
            translation = translations.detect{|t| t.locale == locale.to_s }
            translated_value = translation && translation.send(attribute_name)
            if !translated_value.nil?
              translated_value
            elsif has_attribute?(attribute_name)
              super()
            end
          end
        end
      end

      def self.translation_class_name
        "#{self.name}Translation"
      end

      def self.translation_class
        translation_class_name.constantize
      end

      def translation(locale)
        translations.detect{|t| t.locale.to_sym == locale }
      end

      def build_translations
        I18n.available_locales.each{|locale| translations.find_or_initialize_by(locale: locale.to_s) }
        translations
      end
    end

    def translations_presence
      I18n.available_locales.each do |locale|
        unless translations.any?{|t| t.locale == locale.to_s }
          errors.add(:base, "Translation with locale #{locale} must be present")
        end
      end
    end

  end
end
