class SegmentsController < ApplicationController
  PER_PAGE = 40

  before_action :set_segment

  def show
    @angle = @segment.campaign_angle
    @page = [ params.fetch(:page, 1).to_i, 1 ].max
    @per_page = PER_PAGE
    @total_memberships = @segment.segment_memberships.count
    @total_pages = [ (@total_memberships.to_f / @per_page).ceil, 1 ].max
    @page = [ @page, @total_pages ].min

    @memberships = @segment.segment_memberships
      .includes(:contact)
      .order(score: :desc)
      .offset((@page - 1) * @per_page)
      .limit(@per_page)
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
