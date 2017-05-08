class Admin::AnalyticsController < AdminController
  # GET /admin
  def home
    @totals = [full_snapshot.general, full_snapshot.invitation, full_snapshot.invitation_funnel].reduce(:merge)
  end

  # GET /admin/analytics/growth
  def growth
    history([:count_users, :count_projects])
  end

  # GET /admin/analytics/user_completeness
  def user_completeness
    fields = [
        :count_users,
        :total_user_completeness,
        :count_user_weak_completeness,
        :count_user_medium_completeness,
        :count_user_strong_completeness,
        :count_user_very_strong_completeness
    ]

    history(fields)
  end

  # GET /admin/analytics/invitation_funnel
  def invitation_funnel
    fields = [
        :count_domains,
        *SnapshotService::INVITATION,
        *SnapshotService::INVITATION_FUNNEL
    ]

    history(fields)
  end

  private

  def history(fields)
    @totals = full_snapshot.fields(fields)
    @today = today_snapshot.fields(fields, true)
    @one_day_ago, @two_days_ago = comparison(1.day, fields)
    @one_week_ago, @two_weeks_ago = comparison(1.week, fields)
    @one_month_ago, @two_months_ago = comparison(1.month, fields)
  end

  def full_snapshot
    @full_snapshot ||= SnapshotService.new
  end

  def today_snapshot
    @snapshot ||= SnapshotService.new(Date.today)
  end

  def query_fields(fields)
    fields.map do |field|
      in_funnel = SnapshotService::INVITATION_FUNNEL.include?(field)
      (in_funnel ? "MAX(#{field})" : "SUM(daily_#{field})") + "as #{field}"
    end
  end

  def comparison(interval, fields)
    select_fields = query_fields(fields)

    end_date = Date.today - interval
    start_date = end_date - interval

    values = Snapshot.where('date >= ?', end_date).select(select_fields).all[0]
    base = Snapshot.where('date >= ?', start_date).where('date < ?', end_date).select(select_fields).all[0]

    [values, base]
  end
end
