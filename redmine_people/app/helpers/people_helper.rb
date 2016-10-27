# encoding: utf-8
#
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

module PeopleHelper

  def person_age(age)
    Setting.plugin_redmine_people["hide_age"].to_i > 0 ? '' : "(#{age + 1})"
  end

  def birthday_date(person)
    ages = person_age(person.age)
    if person.birthday.day == Date.today.day && person.birthday.month == Date.today.month
       "#{l(:label_today).capitalize} #{ages}"
    else
      "#{person.birthday.day} #{t('date.month_names')[person.birthday.month]} #{ages}"
    end
  end

  def retrieve_people_query
    if params[:query_id].present?
      @query = PeopleQuery.find(params[:query_id])
      raise ::Unauthorized unless @query.visible?
      session[:people_query] = {:id => @query.id}
      sort_clear
    elsif api_request? || params[:set_filter] || session[:people_query].nil?
      # Give it a name, required to be valid
      @query = PeopleQuery.new(:name => "_")
      @query.build_from_params(params)
      session[:people_query] = {:filters => @query.filters, :group_by => @query.group_by, :column_names => @query.column_names}
    else
      # retrieve from session
      @query = PeopleQuery.find(session[:people_query][:id]) if session[:people_query][:id]
      @query ||= PeopleQuery.new(:name => "_", :filters => session[:people_query][:filters], :group_by => session[:people_query][:group_by], :column_names => session[:people_query][:column_names])
    end
  end

  def people_list_style
    list_styles = people_list_styles_for_select.map(&:last)
    if params[:people_list_style].blank?
      list_style = list_styles.include?(session[:people_list_style]) ? session[:people_list_style] : RedminePeople.default_list_style
    else
      list_style = list_styles.include?(params[:people_list_style]) ? params[:people_list_style] : RedminePeople.default_list_style
    end
    session[:people_list_style] = list_style
  end

  def people_list_styles_for_select
    list_styles = [[l(:label_people_list_excerpt), "list_excerpt"]]
    list_styles += [[l(:label_people_list_list), "list"]]
  end

  def people_principals_check_box_tags(name, principals)
    s = ''
    principals.each do |principal|
      s << "<label>#{ check_box_tag name, principal.id, false, :id => nil } #{principal.is_a?(Group) ? l(:label_group) + ': ' + principal.to_s : principal}</label>\n"
    end
    s.html_safe
  end

  def change_status_link(person)
    return unless User.current.allowed_people_to?(:edit_people, person) && person.id != User.current.id && !person.admin
    url = {:controller => 'people', :action => 'update', :id => person, :page => params[:page], :status => params[:status], :tab => nil}

    if person.locked?
      link_to l(:button_unlock), url.merge(:person => {:status => User::STATUS_ACTIVE}), :method => :put, :class => 'icon icon-unlock'
    elsif person.registered?
      link_to l(:button_activate), url.merge(:person => {:status => User::STATUS_ACTIVE}), :method => :put, :class => 'icon icon-unlock'
    elsif person != User.current
      link_to l(:button_lock), url.merge(:person => {:status => User::STATUS_LOCKED}), :method => :put, :class => 'icon icon-lock'
    end
  end

  def person_tag(person, options={})
    avatar_size = options.delete(:size) || 16
    if person.visible? && !options[:no_link]
      person_avatar = link_to(avatar(person, :size => avatar_size), person_path(person), :id => "avatar")
      person_name = link_to(person.name, person_path(person))
    else
      person_avatar = avatar(person, :size => avatar_size)
      person_name = person.name
    end

    case options.delete(:type).to_s
    when "avatar"
      person_avatar.html_safe
    when "plain"
      person_name.html_safe
    else
      content_tag(:span, "#{person_avatar} #{person_name}".html_safe, :class => "person")
    end
  end
  def person_to_vcard(person)
    card = Vcard::Vcard::Maker.make2 do |maker|

      maker.add_name do |name|
        name.prefix = ''
        name.given = person.firstname.to_s
        name.family = person.lastname.to_s
        name.additional = person.middlename.to_s
      end

      maker.add_addr do |addr|
        addr.preferred = true
        addr.street = person.address.to_s.gsub("\r\n"," ").gsub("\n"," ")
      end

      maker.title = person.job_title.to_s
      maker.org = person.company.to_s
      maker.birthday = person.birthday.to_date unless person.birthday.blank?
      maker.add_note(person.background.to_s.gsub("\r\n"," ").gsub("\n", ' '))

      # maker.add_url(person.website.to_s)

      person.phones.each { |phone| maker.add_tel(phone) }

      maker.add_email(person.email)
    end
    avatar = person.avatar
    card = card.encode.sub("END:VCARD", "PHOTO;BASE64:" + "\n " + [File.open(avatar.diskfile).read].pack('m').to_s.gsub(/[ \n]/, '').scan(/.{1,76}/).join("\n ") + "\nEND:VCARD") if avatar && avatar.readable?

    card.to_s

  end

  def sidebar_people_queries(query_class)
    unless @sidebar_queries
      @sidebar_queries = query_class.visible.
        order("#{query_class.table_name}.name ASC")
    end
    @sidebar_queries
  end

  def people_query_links(title, queries, object_type)
    # links to #index on contacts/show
    return '' unless queries.any?
    url_params = controller_name == "#{object_type}s" ? {:controller => "#{object_type}s", :action => 'index'} : params
    content_tag('h3', title) + "\n" +
      content_tag('ul',
        queries.collect {|query|
            css = 'query'
            css << ' selected' if query == @query
            content_tag('li', link_to(query.name, url_params.merge(:query_id => query), :class => css))
          }.join("\n").html_safe,
        :class => 'queries'
      ) + "\n"
  end

  def render_sidebar_people_queries(object_type)
    query_class = Object.const_get("#{object_type.camelcase}Query")
    out = ''.html_safe
    out << people_query_links(l(:label_my_queries),  sidebar_people_queries(query_class).select(&:is_private?), object_type)
    out << people_query_links(l(:label_query_plural),  sidebar_people_queries(query_class).reject(&:is_private?), object_type)
    out
  end

  def render_people_tabs(tabs)
    if tabs.any?
      render :partial => 'common/people_tabs', :locals => {:tabs => tabs}
    else
      content_tag 'p', l(:label_no_data), :class => "nodata"
    end
  end

end
