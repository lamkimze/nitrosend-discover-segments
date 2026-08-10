class AiAnalysisRun < ApplicationRecord
  STATUSES = %w[pending processing completed failed].freeze

  validates :status, inclusion: { in: STATUSES }

  scope :latest, -> { order(created_at: :desc) }

  def pending? = status == "pending"
  def processing? = status == "processing"
  def completed? = status == "completed"
  def failed? = status == "failed"

  def mark_processing!
    update!(status: "processing", started_at: Time.current, error_message: nil)
  end

  def mark_completed!(segments_found:, summary: {})
    update!(
      status: "completed",
      completed_at: Time.current,
      segments_found: segments_found,
      summary: summary
    )
  end

  def mark_failed!(message)
    update!(
      status: "failed",
      completed_at: Time.current,
      error_message: message
    )
  end
end
