class AddVoteToHelpdeskTickets < ActiveRecord::Migration
  def change
    add_column :helpdesk_tickets, :vote, :integer, :default => nil
    add_column :helpdesk_tickets, :vote_comment, :string
  end
end