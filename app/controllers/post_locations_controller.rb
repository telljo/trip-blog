class PostLocationsController < ApplicationController
  before_action :set_post_location, only: %i[remove_post_location]

  def remove_post_location
    @post_location.destroy

    redirect_to edit_post_url(@post_location.post)
  end

  private

  def set_post_location
    @post_location = PostLocation.find_by(id: params[:id], post_id: params[:post_id])
  end
end
