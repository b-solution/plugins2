class MailchimpEmail
  attr_accessor :id, :email

  def initialize(hsh)
    if hsh.is_a? String
      @email = hsh
    else
      @email = hsh['email']
      @id = hsh['id']
    end
  end

  def belongs_to?(list)
    list.id.in? list_ids
  end

  def campaigns
    @campaigns ||= mailchimp.helper.campaigns_for_email(email: @email).map{ |x| MailchimpCampaign.new(x) }
  rescue
    []
  end

  private

  def list_ids
    @list_ids ||= mailchimp.helper.lists_for_email(:email => @email).map{ |x| x['id'] }
  rescue
    []
  end

  def mailchimp
    MailchimpApi.instance.current
  end

end