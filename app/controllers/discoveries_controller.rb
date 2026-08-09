class DiscoveriesController < ApplicationController
  def create
    result = SegmentDiscoveryService.call
    redirect_to discovery_path(result.discovery_run, fresh: 1)
  end

  def show
    @run = DiscoveryRun.find(params[:id])
    @segments = @run.segments.proposed.includes(:contacts).order(:position)
    @accepted = Segment.accepted.order(:position)
    @insights = @run.insights.ordered
    @fresh = params[:fresh].present?
  end
end
