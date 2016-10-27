# This file is a part of Redmine CRM (redmine_contacts) plugin,
# customer relationship management plugin for Redmine
#
# Copyright (C) 2011-2015 Kirill Bezrukov
# http://www.redminecrm.com/
#
# redmine_contacts is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_contacts is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_contacts.  If not, see <http://www.gnu.org/licenses/>.

require 'acts-as-taggable-on'

module ActsAsTaggableOn::Taggable
  module Core
    module InstanceMethods

      def process_dirty_object(context, new_list)
        value = new_list.is_a?(Array) ? ActsAsTaggableOn::TagList.new(new_list) : new_list
        attrib = "#{context.to_s.singularize}_list"

        if changed_attributes.include?(attrib)
          old = changed_attributes[attrib]
          @changed_attributes.delete(attrib) if old.to_s == value.to_s
        else
          old = tag_list_on(context)
          if self.class.preserve_tag_order
            @changed_attributes[attrib] = old if old.to_s != value.to_s
          else
            @changed_attributes[attrib] = old.to_s if old.sort !=  ActsAsTaggableOn::TagList.new(value.split(',')).sort
          end
        end
      end

      def attributes_for_update(attribute_names)
        filter_tag_lists(super)
      end


      def attributes_for_create(attribute_names)
        filter_tag_lists(super)
      end

      def filter_tag_lists(attributes)
        tag_lists = tag_types.map {|tags_type| "#{tags_type.to_s.singularize}_list"}
        attributes.delete_if {|attr| tag_lists.include? attr }
      end

    end
  end
end
