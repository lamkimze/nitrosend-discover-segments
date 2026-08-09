class SegmentsController < ApplicationController
  before_action :set_segment, only: %i[show update accept dismiss]

  def index
    @contact_count = Contact.count
    @accepted = Segment.accepted.includes(:contacts)
    @latest_run = DiscoveryRun.current
    @proposed = @latest_run ? @latest_run.segments.proposed.includes(:contacts) : Segment.none
    @insights = @latest_run ? @latest_run.insights.ordered : Insight.none
  end

  def show
    @contacts = @segment.contacts.order(:name)
  end

  def update
    if @segment.update(segment_params)
      redirect_to @segment, notice: "Segment name updated."
    else
      @contacts = @segment.contacts.order(:name)
      flash.now[:alert] = "Couldn’t save that name."
      render :show, status: :unprocessable_entity
    end
  end

  def accept
    @segment.accept!
    redirect_to @segment, notice: "Saved. “#{@segment.name}” is ready to use as an audience."
  end

  def dismiss
    @segment.dismiss!
    redirect_to root_path, notice: "Dismissed. You can re-run discovery anytime."
  end

  private

  def set_segment
    @segment = Segment.find(params[:id])
  end

  def segment_params
    params.require(:segment).permit(:name)
  end
end
