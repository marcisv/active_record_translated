require 'spec_helper'

describe ActiveRecordTranslated::Translated do
  let!(:available_locales) { I18n.available_locales = [:en, :lv] }
  before { I18n.locale = available_locales.first }

  let :product_class_definition do
    class Product < ActiveRecord::Base
      translates :name, :description
    end
  end

  before do
    if defined?(Product)
      Product.reset_column_information
      Object.send(:remove_const, :Product)
    end
    product_class_definition
  end

  subject(:product) { Product.new }

  it 'has translations' do
    expect(product).to respond_to :translations
  end

  describe 'validations' do
    it 'is valid without translations by default' do
      expect(product).to be_valid
    end

    context 'when mandatory option is true for an attribute' do
      let :product_class_definition do
        class Product < ActiveRecord::Base
          translates :name, description: {mandatory: true}
        end
      end

      context 'when translations do not exist' do
        it 'has an error for each locale for the field' do
          expect(product).not_to be_valid
          expect(product.errors.count).to eq 2
          expect(product.errors[:description_en]).to be_present
          expect(product.errors[:description_lv]).to be_present
        end

        context 'when only one locale in ActiveRecordTranslated mandatory_locales configuration' do
          let :product_class_definition do
            ActiveRecordTranslated.mandatory_locales = [:lv]
            class Product < ActiveRecord::Base
              translates :name, description: {mandatory: true}
            end
          end

          after { ActiveRecordTranslated.mandatory_locales = nil }

          it 'has error only on mandatory locale' do
            expect(product).not_to be_valid
            expect(product.errors.count).to eq 1
            expect(product.errors[:description_lv]).to be_present
          end
        end
      end

      context 'when translation exists for each locale' do
        let!(:translation_en) { product.translations.build(locale: 'en', description: '') }
        let!(:translation_lv) { product.translations.build(locale: 'lv', description: '') }

        it 'has an error for each locale for the field' do
          expect(product).not_to be_valid
          expect(product.errors.count).to eq 2
          expect(product.errors[:description_en]).to be_present
          expect(product.errors[:description_lv]).to be_present
        end

        context 'when one translations have values' do
          before { translation_en.description = 'desc-en' }

          it 'has error on field with missing translation' do
            expect(product).not_to be_valid
            expect(product.errors.count).to eq 1
            expect(product.errors[:description_lv]).to be_present
          end
        end

        context 'when both translations have values' do
          before do
            translation_en.description = 'desc-en'
            translation_lv.description = 'desc-lv'
          end

          specify { expect(product).to be_valid }
        end
      end
    end

    context 'when mandatory option is :unless_default for an attribute' do
      let(:product_class_definition) do
        ActiveRecord::Base.connection.add_column(:products, :description, :string)
        class Product < ActiveRecord::Base
          translates :name, description: {mandatory: :unless_default}
        end
      end

      after { ActiveRecord::Base.connection.remove_column(:products, :description) }

      context 'when translation with value exists for each locale' do
        let!(:translation_en) { product.translations.build(locale: 'en', description: 'desc-en') }
        let!(:translation_lv) { product.translations.build(locale: 'lv', description: 'desc-lv') }

        specify { expect(product).to be_valid }
      end

      context 'when translations do not exist' do
        it 'has an error for each locale for the field' do
          expect(product).not_to be_valid
          expect(product.errors.count).to eq 2
          expect(product.errors[:description_en]).to be_present
          expect(product.errors[:description_lv]).to be_present
        end

        context 'when default value is empty string' do
          before { product.description = '' }

          it 'has an error for each locale for the field' do
            expect(product).not_to be_valid
            expect(product.errors.count).to eq 2
            expect(product.errors[:description_en]).to be_present
            expect(product.errors[:description_lv]).to be_present
          end
        end

        context 'when default value is empty string and current locale translation is present' do
          before { product.description = '' }
          let!(:translation_en) { product.translations.build(locale: 'en', description: 'desc-en') }

          it 'has an error on other locale field' do
            expect(product).not_to be_valid
            expect(product.errors.count).to eq 1
            expect(product.errors[:description_lv]).to be_present
          end
        end

        context 'when default value exists' do
          before { product.description = 'desc-default' }

          it 'is valid' do
            expect(product).to be_valid
          end
        end
      end
    end
  end

  context 'when mandatory option is a hash with :locales key' do
    context 'when the value is a locale' do
      let(:product_class_definition) do
        class Product < ActiveRecord::Base
          translates name: {mandatory: {locales: :lv}}
        end
      end

      it 'has an error for the locale within locales hash' do
        expect(product).not_to be_valid
        expect(product.errors.count).to eq 1
        expect(product.errors[:name_lv]).to be_present
      end

      context 'when translation exists for the locale' do
        let!(:translation_lv) { product.translations.build(locale: 'lv', name: 'name-lv') }

        it 'is valid' do
          expect(product).to be_valid
        end
      end
    end

    context 'when the value is an array with locales' do
      let(:product_class_definition) do
        class Product < ActiveRecord::Base
          translates name: {mandatory: {locales: [:lv, :en]}}
        end
      end

      it 'has an error for each of the locales' do
        expect(product).not_to be_valid
        expect(product.errors.count).to eq 2
        expect(product.errors[:name_lv]).to be_present
        expect(product.errors[:name_en]).to be_present
      end

      context 'when translation exists for the locales' do
        let!(:translation_en) { product.translations.build(locale: 'en', name: 'name-en') }
        let!(:translation_lv) { product.translations.build(locale: 'lv', name: 'name-lv') }

        it 'is valid' do
          expect(product).to be_valid
        end
      end
    end

    context 'when the value is a proc that returns a locale' do
      let(:product_class_definition) do
        class Product < ActiveRecord::Base
          translates name: {mandatory: {locales: -> product { product.get_locale }}}

          def get_locale
            'lv'
          end
        end
      end

      it 'has an error for the locale returned by proc' do
        expect(product).not_to be_valid
        expect(product.errors.count).to eq 1
        expect(product.errors[:name_lv]).to be_present
      end

      context 'when translation exists for the locale returned by proc' do
        let!(:translation_lv) { product.translations.build(locale: 'lv', name: 'name-lv') }

        it 'is valid' do
          expect(product).to be_valid
        end
      end
    end

    context 'when the value is a proc that returns an array of locales' do
      let(:product_class_definition) do
        class Product < ActiveRecord::Base
          translates name: {mandatory: {locales: -> product { product.get_locales }}}

          def get_locales
            [:lv, :en]
          end
        end
      end

      it 'has an error for each of the locales returned by proc' do
        expect(product).not_to be_valid
        expect(product.errors.count).to eq 2
        expect(product.errors[:name_lv]).to be_present
        expect(product.errors[:name_en]).to be_present
      end

      context 'when translation exists for both of the locales returned by proc' do
        let!(:translation_lv) { product.translations.build(locale: 'lv', name: 'name-lv') }
        let!(:translation_en) { product.translations.build(locale: 'en', name: 'name-en') }

        it 'is valid' do
          expect(product).to be_valid
        end
      end
    end
  end

  describe 'translated attribute' do
    context 'when translations do not exist' do
      specify { expect(product.name).to eq nil }
    end

    context 'when translations exist' do
      before do
        available_locales.each{|locale| product.translations.build(locale: locale, name: "#{locale}-name") }
      end

      it 'responds to translated attribute with all locales' do
        available_locales.each do |locale|
          expect(product.name(locale)).to eq "#{locale}-name"
        end
      end

      it 'uses current locale by default' do
        available_locales.each do |locale|
          I18n.locale = locale
          expect(product.name).to eq "#{locale}-name"
        end
      end

      context 'when attribute name given in hash with options' do
        let(:product_class_definition) do
          class Product < ActiveRecord::Base
            translates name: {mandatory: true}
          end
        end

        it 'responds to translated attribute with all locales' do
          available_locales.each do |locale|
            expect(product.name(locale)).to eq "#{locale}-name"
          end
        end
      end
    end

    context 'when translated model has an attribute with the same name as translated attribute' do
      let(:product_class_definition) do
        ActiveRecord::Base.connection.add_column(:products, :name, :string)
        super()
      end

      before do
        I18n.locale = :en
        product.name = 'default-name'
      end

      after { ActiveRecord::Base.connection.remove_column(:products, :name) }

      it 'responds with its own attribute value' do
        expect(product.name).to eq 'default-name'
      end

      context 'when it has a translation in current locale' do
        before { product.translations.build(locale: 'en', name: en_name) }
        let(:en_name) { 'en-name' }

        it 'responds with translated attribute value' do
          expect(product.name).to eq 'en-name'
        end

        context 'when translation in current locale has no value for attribute' do
          let(:en_name) { nil }

          it 'responds with its own attribute value' do
            expect(product.name).to eq 'default-name'
          end
        end

        context 'when translation in current locale has an empty string value for attribute' do
          let(:en_name) { '' }

          it 'responds with its own attribute value' do
            expect(product.name).to eq 'default-name'
          end
        end
      end
    end
  end

  describe 'saving translations via nested attributes' do
    subject(:product) { Product.create(translations_attributes: translations_attributes) }

    let(:translations_attributes) { [{locale: 'lv', name: 'lv-name', description: 'lv-desc'}] }

    it 'saves model with translations' do
      expect(product).to be_persisted
      expect(product.translations.count).to eq 1
      translation = product.translations.first
      expect(translation.name).to eq 'lv-name'
      expect(translation.description).to eq 'lv-desc'
    end

    context 'when translation for only one of attributes is present' do
      let(:translations_attributes) { [{locale: 'lv', name: 'lv-name', description: ''}] }

      it 'saves model with translation and only present attribute' do
        expect(product).to be_persisted
        expect(product.translations.count).to eq 1
        translation = product.translations.first
        expect(translation.name).to eq 'lv-name'
        expect(translation.description).to eq ''
      end
    end

    context 'when none of translated attributes is present' do
      let(:translations_attributes) { [{locale: 'lv', name: '', description: ''}] }

      it 'saves model without translation' do
        expect(product).to be_persisted
        expect(product.translations.count).to eq 0
      end
    end

  end

  describe '#translations_for_locales' do
    subject(:product) { Product.create }

    let!(:available_locales) { I18n.available_locales = [:en, :lv, :ru] }

    let!(:lv_new_translation) { product.translations.build(locale: 'lv', name: 'lv-name!') }
    let!(:en_persisted_translation) { product.translations.create(locale: 'en', name: 'en-name!') }

    it 'returns new locale' do
      expect(product.translations_for_locales(:lv)).to eq [lv_new_translation]
    end

    it 'returns persisted locale' do
      expect(product.translations_for_locales(:en)).to eq [en_persisted_translation]
    end

    it 'builds translation if it does not exist' do
      expect(product.translations_for_locales(:ru).length).to eq 1
      ru_translation = product.translations_for_locales(:ru)[0]
      expect(ru_translation.new_record?).to eq true
      expect(ru_translation.locale).to eq 'ru'
    end

    it 'returns combination of multiple translations' do
      expect(product.translations_for_locales(:en, :lv)).to eq [en_persisted_translation, lv_new_translation]
    end
  end

  describe '#translations_for_available_locales' do
    subject(:product) { Product.create }

    let!(:available_locales) { I18n.available_locales = [:en, :lv, :ru] }

    let!(:lv_new_translation) { product.translations.build(locale: 'lv', name: 'lv-name!') }
    let!(:en_persisted_translation) { product.translations.create(locale: 'en', name: 'en-name!') }

    it 'returns existing (new and persisted) translations with new records for missing translations in available locales order' do
      expect(product.translations_for_available_locales[0]).to eq en_persisted_translation
      expect(product.translations_for_available_locales[1]).to eq lv_new_translation
      built_ru_translation = product.translations_for_available_locales[2]
      expect(built_ru_translation).to be_present
      expect(built_ru_translation.locale).to eq 'ru'
    end
  end

  describe '#order_by_translation' do
    let!(:available_locales) { I18n.available_locales = [:lv, :ru] }

    let(:lv_name_1){ 'A lv' }
    let(:ru_name_1){ 'Z ru' }

    let(:lv_name_2){ 'Z lv' }
    let(:ru_name_2){ 'A ru' }

    before do
      Product.create(translations_attributes: [{locale: 'lv', name: lv_name_1}, {locale: 'ru', name: ru_name_1}])
      Product.create(translations_attributes: [{locale: 'lv', name: lv_name_2}, {locale: 'ru', name: ru_name_2}])
    end

    context 'when locale is lv' do
      before { I18n.locale = :lv }

      it 'orders by lv attribute' do
        expect(Product.order_by_translation(:name).pluck(:name)).to eq [lv_name_1, lv_name_2]
      end
    end

    context 'when locale is ru' do
      before { I18n.locale = :ru }

      it 'orders by ru name' do
        expect(Product.order_by_translation(:name).pluck(:name)).to eq [ru_name_2, ru_name_1]
      end

      context 'when a product without a translation exists' do
        before do
          product = Product.new
          product.save(validate: false)
          product.translations.delete_all
        end

        it 'returns product without translations as first' do
          expect(Product.order_by_translation(:name).pluck(:name)).to eq [nil, ru_name_2, ru_name_1]
        end

        # context 'with desc argument' do
        #   it 'orders descending' do
        #     expect(Product.order_by_translation(:name, :desc).pluck(:name)).to eq [ru_name_1, ru_name_2, nil]
        #   end
        # end
      end
    end
  end
end
