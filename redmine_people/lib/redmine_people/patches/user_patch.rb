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

require_dependency 'project'
require_dependency 'principal'
require_dependency 'user'

module RedminePeople
  module Patches

    module UserPatch
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable
          if ActiveRecord::VERSION::MAJOR >= 4
            has_one :avatar, lambda { where("#{Attachment.table_name}.description = 'avatar'")}, :class_name => "Attachment", :as  => :container, :dependent => :destroy
          else
            has_one :avatar, :class_name => "Attachment", :as  => :container, :conditions => "#{Attachment.table_name}.description = 'avatar'", :dependent => :destroy
          end
          acts_as_attachable_global

          def self.clear_safe_attributes
            @safe_attributes.collect! do |attrs, options|
              if attrs.collect!(&:to_s).include?('firstname')
                [attrs - ['firstname', 'lastname', 'mail', 'custom_field_values', 'custom_fields'] , options]
              else
                [attrs, options]
              end
            end
          end
          self.clear_safe_attributes

          safe_attributes 'firstname', 'lastname', 'mail', 'custom_field_values', 'custom_fields',
          :if => lambda {|user, current_user| current_user.allowed_people_to?(:edit_people, user) || (user.new_record? && current_user.anonymous? && Setting.self_registration?) }
        end
      end

      module InstanceMethods
        # include ContactsHelper

        def project
          @project ||= Project.new
        end

        def allowed_people_to?(permission, person = nil)
          unless RedminePeople.available_permissions.include?(permission)
            raise "The permission #{permission} does not exist"
          end

          return true if admin?

          if self.respond_to?(:"check_permission_#{permission.to_s}", true)
            self.send("check_permission_#{permission}".to_sym, person)
          else
            has_permission?(permission)
          end
        end

        def has_permission?(permission)
          (self.groups + [self]).map{|principal| PeopleAcl.allowed_to?(principal, permission) }.inject{|memo,allowed| memo || allowed }
        end

        protected

        def check_permission_view_people(person)
          if person && person.is_a?(User) && person.id == self.id
            return true
          elsif self.is_a?(User) && !self.anonymous? && Setting.plugin_redmine_people["visibility"].to_i > 0
            return true
          end
          has_permission?(:view_people)
        end

        def check_permission_edit_people(person)
          if person && person.is_a?(User)
            # Check to edit himself
            if person.id == self.id && Setting.plugin_redmine_people['edit_own_data'].to_i > 0
              return true
            end

            # Check to edit subordinates.
            # Works only for persons.
            if person.respond_to?(:manager_id) && has_permission?(:edit_subordinates) && self.id == person.manager_id
              return true
            end
          end

          has_permission?(:edit_people)
        end

      end
    end

  end
end

unless User.included_modules.include?(RedminePeople::Patches::UserPatch)
  User.send(:include, RedminePeople::Patches::UserPatch)
end
