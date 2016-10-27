class PopulateHelpdeskTicketsMetrics < ActiveRecord::Migration
  def up
    HelpdeskTicket.joins(:issue).readonly(false).each(&:save)
  end

  def down
    #none
  end
end
