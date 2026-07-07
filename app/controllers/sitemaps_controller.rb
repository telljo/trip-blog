class SitemapsController < ApplicationController
  skip_before_action :authenticate

  def show
    @trips = Trip.includes(:posts).order(updated_at: :desc)
    @posts = Post.published.includes(:trip).order(updated_at: :desc)

    respond_to do |format|
      format.xml
    end
  end
end
