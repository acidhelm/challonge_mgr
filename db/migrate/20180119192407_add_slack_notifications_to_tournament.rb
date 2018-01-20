class AddSlackNotificationsToTournament < ActiveRecord::Migration[5.1]
  def change
    add_column :tournaments, :send_slack_notifications, :boolean, default: false
    add_column :tournaments, :slack_notifications_channel, :string
  end
end
