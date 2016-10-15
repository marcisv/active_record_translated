require 'spec_helper'

describe ActiveRecordTranslated::Translated do
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
  let(:available_locales) { I18n.available_locales }

  before { I18n.available_locales = [:en, :lv] }

  it 'has translations' do
    expect(product).to respond_to :translations
  end

  describe 'validations' do
    it 'is valid without translations by default' do
      expect(product).to be_valid
    end

    context 'when mandatory option is true for one of attributes' do
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
      end
    end
  end

  describe '#order_by_translation' do
    before { I18n.available_locales = [:lv, :ru] }

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
