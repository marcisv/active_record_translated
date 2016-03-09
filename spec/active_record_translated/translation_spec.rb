require 'spec_helper'

describe ActiveRecordTranslated::Translation do
  subject(:translation) { ProductTranslation.new(product: product, locale: available_locale.to_s) }
  let(:product) { Product.create }
  let(:available_locale) { :lv }

  before do
    I18n.available_locales = [available_locale]
    I18n.locale = available_locale
  end

  it 'responds to translated object' do
    expect(translation.product).to eq product
  end

  describe 'validations' do
    specify { expect(translation).to be_valid }

    context 'when locale is not present' do
      before { translation.locale = nil }

      specify { expect(translation).not_to be_valid }
    end

    context 'when locale is not in available locales' do
      before { translation.locale = 'en' }

      specify { expect(translation).not_to be_valid }
    end

    context 'when a translation for same locale already exists' do
      before { ProductTranslation.create(product: product, locale: available_locale.to_s) }

      specify { expect(translation).not_to be_valid }
    end
  end

end
