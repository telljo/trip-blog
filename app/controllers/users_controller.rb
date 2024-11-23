class UsersController < ApplicationController
  # GET /users
  def search
    username = search_params[:username]
    @users = User.where.not(id: Current.user.id).where("username LIKE ?", "%#{username}%")

    respond_to do |format|
      format.turbo_stream
    end
  end

  # GET /username/1
  def show
    @user = User.find_by_username(params[:username])
  end

  private

  def search_params
    params.permit(:username)
  end
end
