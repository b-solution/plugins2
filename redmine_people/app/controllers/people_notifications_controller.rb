# This file is a part of Redmine CRM (redmine_contacts) plugin,
# customer relationship management plugin for Redmine
#
# Copyright (C) 2011-2016 Kirill Bezrukov
# http://www.redminecrm.com/
#
# redmine_people is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_people is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_people.  If not, see <http://www.gnu.org/licenses/>.

class PeopleNotificationsController < ApplicationController
  unloadable
  helper :attachments
  helper :people_notifications
  helper :people

  before_filter :check_setting
  before_filter :find_or_create_notification, :except => [:active, :preview, :index]

  def create
    @note.save_attachments(params[:attachments])
    @note.safe_attributes = params[:people_notification]
    if @note.save
      flash[:notice] = l(:notice_successful_create)
      respond_to do |format|
        format.html { redirect_to people_notifications_path }
        format.js
      end
    else
      respond_to do |format|
        format.html { render :action => 'new' }
        format.js
      end
    end
  end

  def index
    raise Unauthorized unless User.current.allowed_people_to?(:edit_notification)
    @notifications = PeopleNotification.for_status(params[:notifications_status])
  end

  def update
    @note.save_attachments(params[:attachments])
    @note.safe_attributes = params[:people_notification]
    if @note.save
      flash[:notice] = l(:label_notification_successful_update)
      respond_to do |format|
        format.html { redirect_to people_notifications_path }
      end
    else
      respond_to do |format|
        format.html { render :edit}
      end
    end
  end

  def preview
    note = PeopleNotification.new
    note.safe_attributes = params[:people_notification]
    @notes = [note]
    render :notification, :layout => false
  end

  def active
    @notes = PeopleNotification.today
    changed_notes = has_change_notifications?(@notes) || []
    @birthdays = ({
      :label_people_birthday_today => Person.today_birthdays.first(8),
      :label_people_birthday_tomorrow => Person.tomorrow_birthdays.first(8),
      :label_people_birthday_this_week => Person.week_birthdays.first(8)
    } if User.current.allowed_people_to?(:view_people) && !session[:birthdays_shown] && RedminePeople.show_birthday_notifications?) || {}
    if ( (session[:notifications_date] != Date.today && !@notes.empty?) || !changed_notes.empty? || @birthdays.values.flatten.any? )
      session[:notifications_date] = Date.today
      @notes = changed_notes unless changed_notes.empty?
      render :notification, :layout => false
      update_notifications_md5(@notes)
    else
      render :nothing => true
    end
  end

  def destroy
    if @note.destroy
      flash[:notice] = l(:notice_successful_delete)
      respond_to do |format|
        format.html { redirect_to people_notifications_path }
        format.api { render_api_ok }
      end
    else
      flash[:error] = l(:notice_unsuccessful_save)
    end
  end

private

  def has_change_notifications?(notes)
    return false unless session[:notifications_md5]
    notes.inject([]) do |answer, note|
      (answer << note) if  Digest::MD5.hexdigest(note.description) != session[:notifications_md5][note.id]
      answer
    end
  end

  def update_notifications_md5(notes)
    session[:notifications_md5] = {} unless session[:notifications_md5]
    session[:birthdays_shown] = true
    notes.each do |note|
      session[:notifications_md5][note.id] =  Digest::MD5.hexdigest(note.description)
    end
  end

  def check_setting
    unless RedminePeople.use_notifications?
      redirect_to :controller => "people_settings", :action => "index"
      return false
    end
  end

  def find_or_create_notification
    if params[:action] == 'new' || params[:action] == 'create'
      @note = PeopleNotification.new
    else
      @note = PeopleNotification.find(params[:id])
    end
    raise Unauthorized unless User.current.allowed_people_to?(:edit_notification)
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
