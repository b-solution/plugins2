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

module Redmine
  module FieldFormat

    class CompanyFormat < RecordList

        add 'company'
        self.customized_class_names = nil
        self.multiple_supported = false

        def label
          "label_crm_company"
        end

        def target_class
          @target_class ||= Contact
        end

        def edit_tag(view, tag_id, tag_name, custom_value, options={})
          contact = Contact.where(:id => custom_value.value).first unless custom_value.value.blank?
          view.select_contact_tag(tag_name, contact, options.merge(:id => tag_id, :display_field => custom_value.value.blank?, :is_company => true))
          # view.text_field_tag(tag_name, custom_value.value, options.merge(:id => tag_id))
        end

        def cast_single_value(custom_field, value, customized = nil)
          Contact.where(:id => value).first unless value.blank?
        end

        def possible_values_options(custom_field, object = nil)
          project = object.respond_to?(:project) && !ContactsSetting.cross_project_contacts? ? object.project : nil
          Contact.visible.by_project(project).where(:is_company => true).order("#{Contact.table_name}.first_name").limit(500).collect{ |c| [ c.to_s, c.id.to_s ] }
        end
    end

  end
end

Redmine::FieldFormat.add 'company', Redmine::FieldFormat::CompanyFormat
