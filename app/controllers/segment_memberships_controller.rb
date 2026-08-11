class SegmentMembershipsController < ApplicationController
  before_action :set_segment

  def destroy
    membership = @segment.segment_memberships.find(params[:id])
    name = membership.contact.full_name
    membership.destroy!
    @segment.refresh_contact_count!

    page = [ params[:page].to_i, 1 ].max
    per_page = SegmentsController::PER_PAGE
    remaining = @segment.segment_memberships.count
    max_page = [ (remaining.to_f / per_page).ceil, 1 ].max
    page = [ page, max_page ].min

    redirect_to segment_path(@segment, page: page),
      notice: "#{name} removed from this audience."
  end

  private

  def set_segment
    @segment = Segment.find(params[:segment_id])
  end
end
