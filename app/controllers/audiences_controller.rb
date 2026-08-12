class AudiencesController < ApplicationController
  def index
    @contact_count = Contact.count
    @pending_count = Contact.pending_allocation.count
    @segments = Segment.active.includes(:segment_memberships)
    @latest = AiAnalysisRun.latest.first

    if params[:analysed].present? && @latest&.completed?
      flash.now[:notice] = notice_for_completed(@latest)
    end
  end

  def show
    redirect_to root_path
  end

  def analyse
    mode = params[:mode].presence_in(AiAnalysisRun::MODES) || "full"

    if mode == "incremental" && Contact.pending_allocation.none?
      redirect_to root_path, alert: "No newly imported contacts to allocate. Import contacts first."
      return
    end

    analysis = AiAnalysisRun.create!(
      status: "pending",
      mode: mode,
      model: ENV.fetch("SEGMENTATION_PROVIDER", "demo")
    )
    AnalyseAudienceJob.perform_later(analysis.id)
    redirect_to analysis_path(analysis)
  end

  private

  def notice_for_completed(run)
    if run.incremental?
      n = run.summary["pending_allocated"].to_i
      "Allocated #{n} new #{'contact'.pluralize(n)} into Smart Audiences. Existing memberships were left as they were."
    else
      count = run.segments_found
      label = count == 1 ? "Smart Audience" : "Smart Audiences"
      "#{count} #{label} refreshed from the latest behaviour."
    end
  end
end
