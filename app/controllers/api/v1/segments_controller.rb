module Api
  module V1
    class SegmentsController < ApplicationController
      protect_from_forgery with: :null_session

      def index
        segments = Segment.active
        render json: segments.map { |s| serialize(s) }
      end

      def show
        render json: serialize(Segment.find(params[:id]), detail: true)
      end

      def contacts
        segment = Segment.find(params[:id])
        memberships = segment.segment_memberships.includes(:contact).order(score: :desc).limit(100)
        render json: {
          segment_id: segment.id,
          contacts: memberships.map do |m|
            {
              id: m.contact_id,
              name: m.contact.full_name,
              email: m.contact.email,
              score: m.score.to_f,
              reason: m.reason
            }
          end
        }
      end

      private

      def serialize(segment, detail: false)
        data = {
          id: segment.id,
          name: segment.name,
          description: segment.description,
          contact_count: segment.contact_count,
          confidence_score: segment.confidence_score.to_f,
          source: segment.source,
          status: segment.status
        }
        data[:evidence] = segment.evidence if detail
        data
      end
    end
  end
end
