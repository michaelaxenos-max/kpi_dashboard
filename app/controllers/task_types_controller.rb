class TaskTypesController < ApplicationController
  before_action :set_task_type, only: [ :edit, :update ]

  def index
    @task_types = TaskType.active.includes(:team).order(:name)
  end

  def edit; end

  def update
    if @task_type.update(task_type_params)
      redirect_to task_types_path, notice: "Hours updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def sync_from_syncer
    result = CorePulse::TaskTypeSyncService.new.sync
    parts = []
    parts << "#{result[:imported]} imported" if result[:imported] > 0
    parts << "#{result[:skipped]} unchanged" if result[:skipped] > 0
    parts << "#{result[:archived]} archived" if result[:archived] > 0
    parts = ["Nothing changed"] if parts.empty?
    notice = "Sync complete — #{parts.join(", ")}."
    redirect_to task_types_path, notice: notice
  rescue => e
    redirect_to task_types_path, alert: "Sync failed: #{e.message}"
  end

  private

  def set_task_type
    @task_type = TaskType.find(params[:id])
  end

  def task_type_params
    if @task_type&.synced?
      params.require(:task_type).permit(:standard_hours)
    else
      params.require(:task_type).permit(:name, :standard_hours, :team_id)
    end
  end
end
