class AnalyseAudienceJob < ApplicationJob
  queue_as :ai_analysis

  # Brief pause so the progress checklist is readable in demos (job is otherwise near-instant).
  DEMO_PACE_SECONDS = 2.4

  def perform(analysis_id)
    sleep DEMO_PACE_SECONDS unless Rails.env.test?
    analysis = AiAnalysisRun.find(analysis_id)
    Segmentation::AnalyseAudience.call(analysis: analysis)
  end
end
