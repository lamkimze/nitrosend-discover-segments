class DemoResetsController < ApplicationController
  def create
    SegmentMembership.delete_all
    Segment.delete_all
    Insight.delete_all
    DiscoveryRun.delete_all
    redirect_to root_path, notice: "Demo reset. Contacts kept — run discovery again."
  end
end
