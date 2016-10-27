resources :mailchimp_memberships, :only => [:create] do
  collection do
    delete '', :action => :destroy
    get :bulk_edit
    post :bulk_update
    get :test_api
  end
end

get 'mailchimp/lists/:project_id/:contact_id', :action => :lists, :controller => :mailchimp
get 'mailchimp/campaigns/:project_id/:contact_id', :action => :campaigns, :controller => :mailchimp
get 'mailchimp/sync/:query_id/with/:list_id', :action => :sync, :controller => :mailchimp