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

module RedminePeople
  module Helper
    def people_tag_url(tag_name, options={})
      {:controller => 'people',
       :action => 'index',
       :set_filter => 1,
       :fields => [:tags],
       :values => {:tags => [tag_name]},
       :operators => {:tags => '='}
      }.merge(options)
    end

    def people_tag_link(tag_name, options={})
      style = RedminePeople.settings[:monochrome_tags].to_i > 0 ? {} : {:style => "background-color: #{people_tag_color(tag_name)}"}
      tag_count = options.delete(:count)
      tag_title = tag_count ? "#{tag_name} (#{tag_count})" : tag_name
      link = link_to tag_title, people_tag_url(tag_name), options
      content_tag(:span, link, {:class => "tag-label-color"}.merge(style))
    end

    def people_tag_color(tag_name)
      "##{"%06x" % (tag_name.unpack('H*').first.hex % 0xffffff)}"
      # "##{"%06x" % (Digest::MD5.hexdigest(tag_name).hex % 0xffffff)}"
      # "##{"%06x" % (tag_name.hash % 0xffffff).to_s}"
    end

    def people_tag_links(tag_list, options={})
      content_tag(
                :span,
                tag_list.map{|tag| people_tag_link(tag, options)}.join(' ').html_safe,
                :class => "tag_list") if tag_list
    end

    def people_tagsedit_with_source_for(field_id, url)
      s = ""
      unless @people_tagsedit_with_source_for
        s << javascript_include_tag(:"tag-it", :plugin => 'redmine_people')
        s << stylesheet_link_tag(:"jquery.tagit.css", :plugin => 'redmine_people')
        @people_tagsedit_with_source_for = true
      end
      s << javascript_tag("$('#{field_id}').tagit({
          tagSource: function(search, showChoices) {
            var that = this;
            $.ajax({
            url: '#{url}',
            data: {q: search.term},
            success: function(choices) {
              showChoices(that._subtractArray(jQuery.parseJSON(choices), that.assignedTags()));
            }
            });
          },
          allowSpaces: true,
          placeholderText: '#{l(:label_people_add_tag)}',
          caseSensitive: false,
          removeConfirmation: true
        });")
      s.html_safe
    end

    def department_tree_tag(person, options={})
      return "" if person.department.blank?
      person.department.self_and_ancestors.map do |department|
        link_to department.name, department_path(department.id, options)
      end.join(' &#187; ').html_safe
    end

  end
end

ActionView::Base.send :include, RedminePeople::Helper
