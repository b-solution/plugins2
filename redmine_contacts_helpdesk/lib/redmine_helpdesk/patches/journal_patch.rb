module RedmineHelpdesk
  module Patches

    module JournalPatch
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable # Send unloadable so it will not be unloaded in development
          has_one :contact, :through => :journal_message
          has_one :journal_message, :dependent => :destroy

          attr_accessor :is_send_note
          attr_accessor :send_note_errors

          after_create :send_note
          after_create :update_helpdesk_ticket
        end
      end


      module InstanceMethods

        def is_incoming?
          self.journal_message && self.journal_message.is_incoming?
        end

        def is_sent?
          self.journal_message && !self.journal_message.is_incoming?
        end

        def message_author
          self.is_incoming? ? self.contact : self.user
        end

        def helpdesk_ticket
          self.journalized.respond_to?(:helpdesk_ticket) && self.journalized.helpdesk_ticket
        end


        def send_note
          require 'timeout'
          if self.issue.customer && self.is_send_note && self.notes
            journal_message = self.journal_message
            begin
              response_options = {:to_address => journal_message.to_address, :cc_address => journal_message.cc_address, :bcc_address => journal_message.bcc_address}
              Timeout::timeout(60) do
                if msg = HelpdeskMailer.issue_response(self.issue.customer, self, response_options).deliver
                  journal_message.message_date = msg.date
                  journal_message.is_incoming = false
                  journal_message.message_id = msg.message_id.to_s.slice(0, 255)
                  journal_message.source = HelpdeskTicket::HELPDESK_EMAIL_SOURCE
                  journal_message.contact = Contact.find_by_emails([msg.to_addrs.first]).first || self.issue.customer
                  journal_message.to_address = msg.to_addrs.first.to_s.slice(0, 255)
                  journal_message.cc_address = msg.cc.join(', ').to_s.slice(0, 255)
                  journal_message.bcc_address = msg.bcc.join(', ').to_s.slice(0, 255)
                  journal_message.save!
                end
              end
            rescue Exception => e
              self.send_note_errors = e.message
            end
          end
        end



        def update_helpdesk_ticket
          return false if helpdesk_ticket.blank? || (helpdesk_ticket && helpdesk_ticket.ticket_date.blank?)
          helpdesk_ticket.save
        end

      end


    end
  end
end

unless Journal.included_modules.include?(RedmineHelpdesk::Patches::JournalPatch)
  Journal.send(:include, RedmineHelpdesk::Patches::JournalPatch)
end
