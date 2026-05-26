class UsersController < ApplicationController
  before_action :require_admin, only: [ :edit, :update ]

  def index
    @users = User.order(:name, :email)
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      redirect_to users_path, notice: "User created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @user = User.find(params[:id])
  end

  def update
    @user = User.find(params[:id])
    if @user.update(password_params)
      redirect_to users_path, notice: "Password updated for #{@user.name.presence || @user.email}."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    user = User.find(params[:id])
    if user == current_user
      redirect_to users_path, alert: "You cannot delete your own account."
    else
      user.destroy
      redirect_to users_path, notice: "User removed."
    end
  end

  private

  def require_admin
    redirect_to users_path, alert: "Not authorized." unless current_user.admin?
  end

  def user_params
    params.expect(user: [ :name, :email, :password, :password_confirmation ])
  end

  def password_params
    params.expect(user: [ :password, :password_confirmation ])
  end
end
