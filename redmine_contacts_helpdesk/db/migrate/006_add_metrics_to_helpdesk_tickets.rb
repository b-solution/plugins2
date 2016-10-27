class AddMetricsToHelpdeskTickets < ActiveRecord::Migration
  def change
    add_column :helpdesk_tickets, :reaction_time, :integer
    add_column :helpdesk_tickets, :first_response_time, :integer
    add_column :helpdesk_tickets, :resolve_time, :integer
    add_column :helpdesk_tickets, :last_agent_response_at, :datetime
    add_column :helpdesk_tickets, :last_customer_response_at, :datetime
  end
end
