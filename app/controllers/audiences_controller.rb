class AudiencesController < ApplicationController
  def index
    @contact_count = Contact.count
    @segments = Segment.active.includes(:segment_memberships)
    @latest = AiAnalysisRun.latest.first
  end

  def show
    redirect_to root_path
  end

  def analyse
    analysis = AiAnalysisRun.create!(status: "pending", model: ENV.fetch("SEGMENTATION_PROVIDER", "demo"))
    AnalyseAudienceJob.perform_later(analysis.id)
    redirect_to analysis_path(analysis)
  end
end
