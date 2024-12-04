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
    update_params = user_params.except(:cropped_image_data)

    if @user.update(update_params)
      flash[:notice] = "Profile was successfully updated."
      if user_params[:cropped_image_data].present?
        @user.profile_picture.attach(
          io: StringIO.new(Base64.decode64(user_params[:cropped_image_data].split(",")[1])),
          filename: "cropped_image.jpg",
          content_type: "image/jpeg"
          )
      end
      redirect_to edit_user_path(@user.username)
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
    params.require(:user).permit(:username, :profile_picture, :cropped_image_data)
  end
end
