class MailchimpController < ApplicationController
  before_filter :find_contact, :except => [ :sync ]
  before_filter :find_project, :except => [ :sync ]
  before_filter :require_admin

  def sync
    @query = ContactQuery.find(params[:query_id])
    @query_emails = @query.objects_scope.joins(:projects).where('email IS NOT NULL').where("email <> ''").pluck(:email).map(&:strip)
    @list = MailchimpList.find_by_id(params[:list_id])
    @list_emails = @list.members
    @to_subscribe = @query_emails - @list_emails
    @list.bulk_subscribe(@to_subscribe.map{ |x| Contact.find_by_email(x) }.compact)
    render json: { :success => true }
  end

  private

  def find_contact
    @contact = Contact.find(params[:contact_id])
  end

  def find_project
    @project = Project.find(params[:project_id])
  end
end
