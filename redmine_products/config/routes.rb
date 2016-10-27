# This file is a part of Redmine Products (redmine_products) plugin,
# customer relationship management plugin for Redmine
#
# Copyright (C) 2011-2015 Kirill Bezrukov
# http://www.redminecrm.com/
#
# redmine_products is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_products is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_products.  If not, see <http://www.gnu.org/licenses/>.

# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

resources :products do
  collection do
    get :bulk_edit, :context_menu
    post :bulk_edit, :bulk_update, :add
    delete :bulk_destroy
  end
end
resources :product_imports, :only => [:new, :create]

resources :orders do
  collection do
    get :bulk_edit, :context_menu
    post :bulk_edit, :bulk_update
    delete :bulk_destroy
  end
end

resources :order_comments, :only => [:create, :destroy]

resources :projects do
  resources :products, :only => [:index, :new, :create]
  resources :orders, :only => [:index, :new, :create]
end

resources :products_issues do
  collection do
    get :autocomplete_for_product
    post :add
  end
end

resources :order_statuses, :except => :show

resources :product_categories

match 'invoices/add_product_line' => 'invoices#add_product_line', :via => :post, :as => 'add_invoice_product_line'
match 'auto_completes/products' => 'auto_completes#products', :via => :get, :as => 'auto_complete_products'
match 'auto_completes/orders' => 'auto_completes#orders', :via => :get, :as => 'auto_complete_orders'
