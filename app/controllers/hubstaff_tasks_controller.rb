class HubstaffTasksController < ApplicationController
  def merge
    keep      = HubstaffTask.find(params[:keep_task_id])
    all_tasks = HubstaffTask.where(id: params[:task_ids])

    all_tasks.update_all(merged_into_id: nil)
    all_tasks.where.not(id: keep.id).update_all(merged_into_id: keep.id)

    DailyKpiSummary.recalculate_for(keep.team_member, keep.date)

    respond_to do |format|
      format.turbo_stream { render_task_group_stream(keep, params[:task_ids]) }
      format.html { redirect_to team_member_path(keep.team_member, date: keep.date.iso8601) }
    end
  end

  def unmerge
    tasks = HubstaffTask.where(id: params[:task_ids])
    tasks.update_all(merged_into_id: nil)

    first = tasks.first
    DailyKpiSummary.recalculate_for(first.team_member, first.date)

    respond_to do |format|
      format.turbo_stream { render_task_group_stream(first, params[:task_ids]) }
      format.html { redirect_to team_member_path(first.team_member, date: first.date.iso8601) }
    end
  end

  private

  def render_task_group_stream(task, task_ids)
    tasks = HubstaffTask.includes(:task_type, :project, :merged_tasks)
                        .where(id: task_ids)
                        .order(:summary)

    group = {
      visible: tasks.select { |t| t.merged_into_id.nil? },
      all:     tasks.to_a
    }

    multi_day_tasks = CorePulse::MultiDayTaskMetadata.build(tasks.to_a)

    frame_id = "task_group_#{task.team_member_id}_#{task.date}_#{task.project_id}"

    render turbo_stream: turbo_stream.replace(
      frame_id,
      partial: "team_members/task_group",
      locals: {
        member:            task.team_member,
        project:           task.project,
        group:             group,
        is_funnel_builder: task.team_member.team&.name == "Funnel Builders",
        multi_day_tasks:   multi_day_tasks
      }
    )
  end
end
