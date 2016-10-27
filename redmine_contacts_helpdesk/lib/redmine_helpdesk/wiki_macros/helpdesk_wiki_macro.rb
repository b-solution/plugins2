module RedmineHelpdesk
  module WikiMacros

    Redmine::WikiFormatting::Macros.register do
      desc "Mail icon Macro"
      macro :mail do |obj, args|
        "<span class=\"icon icon-email\"/>"
      end

      desc "Helpdesk send_file macro"
      macro :send_file do |obj, args|
        return "" unless obj.is_a?(Issue) || obj.is_a?(Journal)
        issue = obj.is_a?(Journal) ? obj.issue : obj
        return "" unless issue.respond_to?(:customer) || (issue.respond_to?(:customer) && issue.customer.blank?)
        args, options = extract_macro_options(args, :parent)
        raise 'No or bad arguments.' if args.size < 1
        attachment = issue.attachments.where(:filename => args.first).first

        link_to_attachment attachment if attachment
      end
    end



  end
end
