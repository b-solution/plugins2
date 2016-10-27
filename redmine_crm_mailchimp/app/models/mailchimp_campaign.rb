class MailchimpCampaign
  attr_accessor :id, :title, :subject, :send_time, :web_id

  def initialize(hsh)
    @web_id = hsh['web_id']
    @id = hsh['id']
    @title = hsh['title']
    @subject = hsh['subject']
    @send_time = hsh['send_time']
  end
end