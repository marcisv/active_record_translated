RSpec.configure do |config|
  config.before :all do
    ActiveRecord::Base.establish_connection adapter: 'sqlite3', database: ':memory:'
    # ActiveRecord::Schema.verbose = false
    ActiveRecord::Base.connection.create_table :products
    ActiveRecord::Base.connection.create_table :product_translations do |t|
      t.references :product
      t.string  :locale
      t.string  :name
      t.string  :description
    end

    class Product < ActiveRecord::Base
      translates :name, :description
    end

    class ProductTranslation < ActiveRecord::Base
      include ActiveRecordTranslated::Translation
    end
  end

  config.after do
    [Product, ProductTranslation].each(&:destroy_all)
  end
end
