class SegmentsController < ApplicationController
  def show
    @segment = Segment.find(params[:id])
    @memberships = @segment.segment_memberships.includes(:contact).order(score: :desc)
  end
end
