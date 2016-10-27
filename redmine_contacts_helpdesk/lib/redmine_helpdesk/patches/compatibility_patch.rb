if Redmine::VERSION.to_s < '2.4'
  def accept_attachment?(attachment)
    true
  end
end
