#custom routes for this plugin
resources :helpdesk_tickets, :only => [:edit, :destroy, :update]

resources :projects do
  resources :canned_responses, :only => [:new, :create]
end

resources :canned_responses do
  collection do
    post :add 
  end
end

match "helpdesk_mailer" => "helpdesk_mailer#index",:via => [:get, :post]
match "helpdesk_mailer/get_mail" => "helpdesk_mailer#get_mail", :via => [:get, :post, :put]
match "helpdesk/save_settings" => "helpdesk#save_settings", :via => [:get, :post, :put ]
match "helpdesk/get_mail" => "helpdesk#get_mail", :via => [:get, :post, :put]
match "helpdesk/delete_spam" => "helpdesk#delete_spam", :via => [:delete]
match "helpdesk/email_note.:format" => "helpdesk#email_note", :via => [:get, :post]
match "helpdesk/create_ticket.:format" => "helpdesk#create_ticket", :via => [:get, :post]
match "helpdesk/show_original" => "helpdesk#show_original", :via => [:get, :post]
match "helpdesk_reports/index/(:project_id)" => 'helpdesk_reports#index', :via => [:get, :post]
match "helpdesk_reports/staff_report/(:project_id)" => 'helpdesk_reports#staff_report', :via => [:get, :post]
match "helpdesk_reports/tickets_report/(:project_id)" => 'helpdesk_reports#tickets_report', :via => [:get, :post]

get "mail_fetcher/receive_imap" => "mail_fetcher#receive_imap"
get "mail_fetcher/receive_pop3" => "mail_fetcher#receive_pop3"

match 'tickets/:id/:hash' => 'public_tickets#show', :as => :public_ticket, :via => [:get, :post]
match 'tickets/:id/add_comment/:hash' => 'public_tickets#add_comment', :as => :public_ticket_add_comment, :via => [:get, :post]

match 'vote/:id/:hash' => 'helpdesk_votes#show', :via => :get, :as => 'helpdesk_votes_show'
match 'vote/:id/:hash' => 'helpdesk_votes#vote', :via => :post, :as => 'helpdesk_votes_vote'
match 'vote/:id/:vote/:hash' => 'helpdesk_votes#fast_vote', :via => :get, :as => 'helpdesk_votes_fast_vote'

get 'attachments/:id/:ticket_id/:hash/:filename', :to => 'attachments#show', :id => /\d+/, :filename => /.*/, :as => 'hashed_named_attachment'
get 'attachments/download_hashed/:id/:ticket_id/:hash/:filename', :to => 'attachments#download', :id => /\d+/, :filename => /.*/, :as => 'hashed_download_named_attachment'
