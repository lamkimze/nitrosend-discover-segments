class AnalyseAudienceJob < ApplicationJob
  queue_as :ai_analysis

  def perform(analysis_id)
    analysis = AiAnalysisRun.find(analysis_id)
    Segmentation::AnalyseAudience.call(analysis: analysis)
  end
end
