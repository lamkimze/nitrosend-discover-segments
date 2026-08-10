class AnalysesController < ApplicationController
  def show
    @analysis = AiAnalysisRun.find(params[:id])
    @segments = Segment.active.order(confidence_score: :desc) if @analysis.completed?
  end
end
