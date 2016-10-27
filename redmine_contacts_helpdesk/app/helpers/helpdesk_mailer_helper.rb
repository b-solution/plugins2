# encoding: utf-8
# include RedCloth

module HelpdeskMailerHelper
  def textile(text)
    Redmine::WikiFormatting.to_html(Setting.text_formatting, text)
  end
end