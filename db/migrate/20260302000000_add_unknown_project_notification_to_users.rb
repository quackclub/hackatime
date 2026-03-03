class AddUnknownProjectNotificationToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :notify_unknown_project, :boolean, default: true, null: false
    add_column :users, :unknown_project_notified_at, :datetime

    reversible do |dir|
      dir.up do
        # Existing users should have this off by default
        execute "UPDATE users SET notify_unknown_project = false WHERE notify_unknown_project = true"
      end
    end
  end
end
