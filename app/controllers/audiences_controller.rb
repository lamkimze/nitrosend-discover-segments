class AudiencesController < ApplicationController
  def index
    @contact_count = Contact.count
    @segments = Segment.active.includes(:segment_memberships)
    @latest = AiAnalysisRun.latest.first

    if params[:analysed].present? && @latest&.completed?
      count = @latest.segments_found
      label = count == 1 ? "Smart Audience" : "Smart Audiences"
      flash.now[:notice] = "#{count} #{label} ready to pick in Campaigns."
    end
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
