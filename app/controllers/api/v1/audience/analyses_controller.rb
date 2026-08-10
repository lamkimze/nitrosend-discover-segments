module Api
  module V1
    module Audience
      class AnalysesController < ApplicationController
        protect_from_forgery with: :null_session

        def create
          analysis = AiAnalysisRun.create!(status: "pending", model: ENV.fetch("SEGMENTATION_PROVIDER", "demo"))
          AnalyseAudienceJob.perform_later(analysis.id)
          render json: {
            id: analysis.id,
            status: analysis.status
          }, status: :accepted
        end

        def show
          analysis = AiAnalysisRun.find(params[:id])
          render json: {
            id: analysis.id,
            status: analysis.status,
            model: analysis.model,
            contact_count: analysis.contact_count,
            segments_found: analysis.segments_found,
            error_message: analysis.error_message,
            summary: analysis.summary,
            started_at: analysis.started_at,
            completed_at: analysis.completed_at
          }
        end
      end
    end
  end
end
