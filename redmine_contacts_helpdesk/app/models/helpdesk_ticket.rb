class HelpdeskTicket < ActiveRecord::Base
  HELPDESK_EMAIL_SOURCE = 0
  HELPDESK_WEB_SOURCE = 1
  HELPDESK_PHONE_SOURCE = 2
  HELPDESK_TWITTER_SOURCE = 3
  HELPDESK_CONVERSATION_SOURCE = 4

  SEND_AS_NOTIFICATION = 1
  SEND_AS_MESSAGE = 2

  attr_accessible :vote, :vote_comment,:from_address,
                  :to_address, :cc_address, :ticket_date,
                  :message_id, :is_incoming, :customer, :issue, :source, :contact_id, :ticket_time
  
  attr_accessor :ticket_time

  unloadable
  belongs_to :customer, :class_name => 'Contact', :foreign_key => 'contact_id'
  belongs_to :issue
  has_one :message_file, :class_name => "Attachment", :as  => :container, :dependent => :destroy

  acts_as_attachable :view_permission => :view_issues,
                     :delete_permission => :edit_issues


  if ActiveRecord::VERSION::MAJOR >= 4
    acts_as_activity_provider :type => 'helpdesk_tickets',
                              :permission => :view_helpdesk_tickets,
                              :timestamp => "#{table_name}.ticket_date",
                              :author_key => "#{Issue.table_name}.author_id",
                              :scope => eager_load(:issue => :project)
  else
    acts_as_activity_provider :type => 'helpdesk_tickets',
                              :permission => :view_helpdesk_tickets,
                              :timestamp => "#{table_name}.ticket_date",
                              :author_key => "#{Issue.table_name}.author_id",
                              :find_options => {:include => {:issue => :project}}
  end

  acts_as_event :datetime => :ticket_date,
                :project_key => "#{Project.table_name}.id",
                :url => Proc.new {|o| {:controller => 'issues', :action => 'show', :id => o.issue_id}},
                :type => Proc.new {|o| 'icon-email' + (o.issue.closed? ? ' closed' : '') if o.issue },
                :title => Proc.new {|o| "##{o.issue.id} (#{o.issue.status}): #{o.issue.subject}" if o.issue },
                :author => Proc.new {|o|  o.customer},
                :description => Proc.new{|o| o.issue.description if o.issue}

  accepts_nested_attributes_for :customer

  before_save :calculate_metrics
  validates_presence_of :customer, :ticket_date

  def initialize(attributes=nil, *args)
    super
    if new_record?
      # set default values for new records only
      self.ticket_date ||= Time.now
      self.source ||= HelpdeskTicket::HELPDESK_EMAIL_SOURCE
    end
  end

  def ticket_time
    self.ticket_date.to_s(:time) unless self.ticket_date.blank?
  end

  def ticket_time=(val)
    if !self.ticket_date.blank? && val.to_s.gsub(/\s/, "").match(/^(\d{1,2}):(\d{1,2})$/)
      self.ticket_date = self.ticket_date.change({:hour => $1.to_i % 24, :min => $2.to_i % 60})
    end
  end

  def recalculate_events
    unless issue.closed?
      close_journal_id = nil
    end
  end

  def available_addresses
    @available_addresses ||= ([self.default_to_address] | self.customer.emails.map{|e| e} | [self.from_address.blank? ? nil : self.from_address.downcase.strip]).compact.uniq if self.customer
  end

  def default_to_address
    address = self.from_address.blank? ? "" : self.from_address.downcase.strip
    self.customer.emails.include?(address) ? address : self.customer.primary_email
  end

  def cc_addresses
    @cc_addresses = ((self.issue.contacts ? self.issue.contacts.map(&:primary_email) : []) | cc_address.to_s.split(',')).compact.uniq
  end

  def project
    issue.project if issue
  end

  def author
    issue.author if issue
  end

  def customer_name
  	customer.name if customer
  end

  def responses
    @responses ||= JournalMessage.
      eager_load(:journal).
      where(:journals => {:journalized_id => self.issue_id}).
      order("#{JournalMessage.table_name}.message_date ASC")
  end

  def reaction_date
    @reaction_date ||= self.issue.journals.
      eager_load(:journal_message).
      where("#{JournalMessage.table_name}.journal_id IS NULL OR #{JournalMessage.table_name}.is_incoming = ?", false).
      order("#{Journal.table_name}.created_on ASC").
      first.
      try(:created_on).try(:utc)
  end

  def first_response_date
    @first_response_date ||= self.responses.select{|r| !r.is_incoming? }.first.try(:message_date).try(:utc)
  end

  def last_response_time
    @last_response_time ||= last_journal_message && last_journal_message.is_incoming? && !self.issue.closed? ? last_journal_message.message_date.utc : nil
  end

  def last_agent_response
    @last_agent_response ||= self.responses.select{|r| !r.is_incoming? }.last
  end

  def last_journal_message
    @last_journal_message ||= self.responses.last
  end

  def last_customer_response
    @last_customer_response ||= self.responses.select{|r| r.is_incoming? }.last
  end

  def average_response_time

  end

  def ticket_source_name
    case self.source
      when HelpdeskTicket::HELPDESK_EMAIL_SOURCE then l(:label_helpdesk_tickets_email)
      when HelpdeskTicket::HELPDESK_PHONE_SOURCE then l(:label_helpdesk_tickets_phone)
      when HelpdeskTicket::HELPDESK_WEB_SOURCE then l(:label_helpdesk_tickets_web)
      when HelpdeskTicket::HELPDESK_TWITTER_SOURCE then l(:label_helpdesk_tickets_twitter)
      when HelpdeskTicket::HELPDESK_CONVERSATION_SOURCE then l(:label_helpdesk_tickets_conversation)
      else ""
    end
  end

  def ticket_source_icon
    case self.source
      when HelpdeskTicket::HELPDESK_EMAIL_SOURCE then "icon-email"
      when HelpdeskTicket::HELPDESK_PHONE_SOURCE then "icon-call"
      when HelpdeskTicket::HELPDESK_WEB_SOURCE then "icon-web"
      when HelpdeskTicket::HELPDESK_TWITTER_SOURCE then "icon-twitter"
      else "icon-helpdesk"
    end
  end

  def content
    issue.description if issue
  end

  def customer_email
  	customer.primary_email if customer
  end

  def last_message
    @last_message ||= JournalMessage.eager_load(:journal => :issue).where(:issues => {:id => issue.id}).order("#{Journal.table_name}.created_on ASC").last || self
  end

  def last_message_date
    last_message.is_a?(HelpdeskTicket) ? self.ticket_date : last_message.message_date if last_message
  end

  def ticket_date
    return nil if super.blank?
    zone = User.current.time_zone
    zone ? super.in_time_zone(zone) : (super.utc? ? super.localtime : super)
  end

  def token
    Digest::MD5.hexdigest("#{issue.id}:#{ticket_date.strftime('%d.%m.%Y %H:%M:%S')}:#{Rails.application.config.secret_token}")
  end

  def calculate_metrics
    self.reaction_time = reaction_date - ticket_date.utc if reaction_date && ticket_date
    self.first_response_time = first_response_date - ticket_date.utc if first_response_date && ticket_date
    self.resolve_time = self.issue.closed? ? self.issue.closed_on - ticket_date.utc : nil if ticket_date && self.issue.closed_on && last_agent_response
    self.last_agent_response_at = last_agent_response.message_date if last_agent_response
    self.last_customer_response_at = last_customer_response.message_date if last_customer_response
  end

  def self.vote_message(vote)
    case vote.to_i
    when 0
      l(:label_helpdesk_mark_notgood)
    when 1
      l(:label_helpdesk_mark_justok)
    when 2
      l(:label_helpdesk_mark_awesome)
    else
      ""
    end
  end

  def update_vote(new_vote, comment = nil)
    old_vote = vote
    old_vote_comment = vote_comment
    if update_attributes(:vote => new_vote, :vote_comment => comment )
      if old_vote != vote || old_vote_comment != vote_comment
        journal = Journal.new(:journalized => issue, :user => User.current)
        journal.details << JournalDetail.new(:property => 'attr',
                                              :prop_key => 'vote',
                                              :old_value => old_vote,
                                              :value => vote) if old_vote != vote
        journal.details << JournalDetail.new(:property => 'attr',
                                              :prop_key => 'vote_comment',
                                              :old_value => old_vote_comment,
                                              :value => vote_comment) if old_vote_comment != vote_comment
        journal.save
      end
    end
  end

end
