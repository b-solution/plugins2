class HelpdeskVotesController < ApplicationController
  unloadable
  layout 'public_tickets'
  skip_before_filter :check_if_login_required
  before_filter :find_ticket, :authorize_ticket
  before_filter :fill_data

  helper :issues

  def vote
    @ticket.update_vote(params[:vote], params[:vote_comment]) if params[:vote]
  end

  def fast_vote
    if RedmineHelpdesk.vote_comment_allow?
      @ticket.vote = params[:vote] if params[:vote]
      render :action => "show"
    else
      @ticket.update_vote(params[:vote]) if params[:vote]
      render :action => "vote"
    end
  end

private

  def find_ticket
    @ticket = HelpdeskTicket.find(params[:id])
    @issue = @ticket.issue
    @project = @issue.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def authorize_ticket(action = params[:action])
    allow = true
    allow &&= (@ticket.token == params[:hash]) && RedmineHelpdesk.vote_allow?
    allow &&= !@issue.is_private
    render_404 unless allow
  end

  def fill_data
    @previous_tickets = @ticket.customer.tickets.where(:is_private => false).includes([:status, :helpdesk_ticket]).order_by_status
    @total_spent_hours = @previous_tickets.map.sum(&:total_spent_hours)
  end

end
