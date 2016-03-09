module ActiveRecordTranslated
  module Translation
    extend ActiveSupport::Concern

    included do
      translateable = self.name.split('Translation').first.underscore.to_sym
      belongs_to translateable
      validates translateable, presence: true
      validates :locale,
        presence:   true,
        inclusion:  { in: -> t { I18n.available_locales.map(&:to_s) }, if: :locale? },
        uniqueness: { scope: :"#{translateable}_id" }
    end

  end
end
