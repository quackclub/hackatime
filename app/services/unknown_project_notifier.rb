class UnknownProjectNotifier
  THRESHOLD_SECONDS = 5 * 60

  def self.notify_if_threshold_reached(user)
    return unless user&.notify_unknown_project
    return if user.unknown_project_notified_at.present?

    seconds = Heartbeat.where(user_id: user.id)
                     .where("project IS NULL OR project = '' OR project = 'Unknown'")
                     .coding_only
                     .duration_seconds

    return if seconds < THRESHOLD_SECONDS

    # Send Slack DM if available
    begin
      if user.slack_uid.present? && user.slack_access_token.present?
        open_resp = HTTP.auth("Bearer #{user.slack_access_token}")
                    .post("https://slack.com/api/conversations.open", form: { users: user.slack_uid })
        open_body = JSON.parse(open_resp.body.to_s) rescue {}
        channel = open_body.dig("channel", "id")
        if channel
          HTTP.auth("Bearer #{user.slack_access_token}")
              .post("https://slack.com/api/chat.postMessage", json: { channel: channel, text: slack_message })
        end
      end
    rescue => e
      Rails.logger.error("UnknownProjectNotifier: slack send error #{e.class}: #{e.message}")
      Sentry.capture_exception(e)
    end

    # Send email to primary address
    begin
      primary = user.email_addresses.first&.email
      if primary.present?
        UnknownProjectMailer.notify_unknown_project(user).deliver_later
      end
    rescue => e
      Rails.logger.error("UnknownProjectNotifier: email send error #{e.class}: #{e.message}")
      Sentry.capture_exception(e)
    end

    user.update!(unknown_project_notified_at: Time.current)
  end

  def self.slack_message
    "We noticed you’ve logged some time in ‘Unknown’ — make sure you’re inside a git repository or set the project name so your time is attributed correctly."
  end
end
