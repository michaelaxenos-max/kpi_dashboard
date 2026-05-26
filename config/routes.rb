Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  mount MissionControl::Jobs::Engine, at: "/jobs"

  get    "login",  to: "sessions#new",     as: :login
  post   "login",  to: "sessions#create"
  delete "logout", to: "sessions#destroy", as: :logout

  root "dashboard#index"

  get "dashboard", to: "dashboard#index", as: :dashboard

  # Weekly and monthly calendar views
  get "calendar/weekly", to: "calendar#weekly", as: :weekly_calendar
  get "calendar/monthly", to: "calendar#monthly", as: :monthly_calendar

  # Per-member views
  resources :team_members, only: [ :index, :show ]
  resources :hubstaff_tasks, only: [] do
    collection do
      post :merge
      post :unmerge
    end
  end

  # User management (login-protected, no public registration)
  resources :users, only: [ :index, :new, :create, :edit, :update, :destroy ]

  # Settings
  resources :teams, only: [ :index, :show, :edit, :update ]
  resources :task_types, only: [ :index, :edit, :update ]

  # Manual Hubstaff sync
  post "sync", to: "sync#create", as: :sync

  # Sync task types from Hubstaff Syncer app
  post "task_types/sync_from_syncer", to: "task_types#sync_from_syncer", as: :sync_task_types_from_syncer
end
