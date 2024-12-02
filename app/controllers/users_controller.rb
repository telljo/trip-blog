class UsersController < ApplicationController
  before_action :set_user, only: %i[show edit update destroy]

  # GET /username/1
  def show
  end

  # GET /posts/1/edit
  def edit
  end

  def destroy
    @user.destroy
    redirect_to root
  end

  def update
    @user = User.find_by_username(params[:username])

    if @user.update(user_params)
      flash[:notice] = "Profile was successfully updated."
      redirect_to @user
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = User.find_by_username(params[:username])
  end

  # Only allow a list of trusted parameters through.
  def user_params
    params.require(:user).permit(:username, :profile_picture)
  end
end
