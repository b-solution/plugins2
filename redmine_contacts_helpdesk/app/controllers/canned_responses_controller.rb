class CannedResponsesController < ApplicationController
  unloadable

  before_filter :find_canned_response, :except => [:new, :create, :index]
  before_filter :find_optional_project, :only => [:new, :create, :add, :destroy]
  before_filter :find_issue, :only => [:add]
  before_filter :require_admin, :only => [:index]

  accept_api_auth :index


  def index
    case params[:format]
    when 'xml', 'json'
      @offset, @limit = api_offset_and_limit
    else
      @limit = per_page_option
    end

    scope = CannedResponse.visible
    scope = scope.in_project_or_public(@project) if @project

    @canned_response_count = scope.count
    @canned_response_pages = Paginator.new @canned_response_count, @limit, params['page']
    @offset ||= @canned_response_pages.offset
    @canned_responses = scope.all(:limit => @limit, :offset => @offset, :order => "#{CannedResponse.table_name}.name")

    respond_to do |format|
      format.html
    end
  end

  def add
    @content = HelpdeskMailer.apply_macro(@canned_response.content, @issue.customer, @issue, User.current)
  end

  def new
    @canned_response = CannedResponse.new
    @canned_response.user = User.current
    @canned_response.project = @project
    @canned_response.is_public = false unless User.current.allowed_to?(:manage_public_canned_responses, @project) || User.current.admin?
  end

  def create
    @canned_response = CannedResponse.new(params[:canned_response])
    @canned_response.user = User.current
    @canned_response.project = params[:canned_response_is_for_all] ? nil : @project
    @canned_response.is_public = false unless User.current.allowed_to?(:manage_public_canned_responses, @project) || User.current.admin?

    if @canned_response.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to_project_or_global
    else
      render :action => 'new', :layout => !request.xhr?
    end
  end

  def edit
  end

  def update
    @canned_response.attributes = params[:canned_response]
    @canned_response.project = nil if params[:canned_response_is_for_all]
    @canned_response.is_public = false unless User.current.allowed_to?(:manage_public_canned_responses, @project) || User.current.admin?

    if @canned_response.save
      flash[:notice] = l(:notice_successful_update)
      redirect_to_project_or_global
    else
      render :action => 'edit'
    end
  end

  def destroy
    @canned_response.destroy
    redirect_to_project_or_global
  end

private
  def redirect_to_project_or_global
    redirect_to @project ? settings_project_path(@project, :tab => 'helpdesk_canned_responses') : canned_responses_path
  end

  def find_issue
    @issue = Issue.find(params[:issue_id])
    @project = @issue.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_canned_response
    @canned_response = CannedResponse.find(params[:id])
    @project = @canned_response.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end
