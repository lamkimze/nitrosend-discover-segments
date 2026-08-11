class SegmentsController < ApplicationController
  before_action :set_segment

  def show
    @memberships = @segment.segment_memberships.includes(:contact).order(score: :desc)
    @angle = @segment.campaign_angle
  end

  def archive
    @segment.archive!
    redirect_to root_path, notice: "Audience dismissed. Contacts are unchanged — you can re-analyse anytime."
  end

  private

  def set_segment
    @segment = Segment.find(params[:id])
  end
end
