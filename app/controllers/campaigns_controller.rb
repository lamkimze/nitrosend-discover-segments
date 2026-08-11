class CampaignsController < ApplicationController
  before_action :set_segment, only: %i[new create]
  before_action :set_campaign, only: %i[show update]

  def new
    angle = @segment.campaign_angle
    @campaign = @segment.campaigns.build(
      subject: angle[:subject],
      content: default_content(@segment)
    )
  end

  def create
    @campaign = @segment.campaigns.build(campaign_params.merge(status: "draft"))
    if @campaign.save
      redirect_to @campaign, notice: "Draft campaign ready — audience already selected."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
  end

  def update
    if @campaign.update(campaign_params.merge(status: "saved"))
      redirect_to @campaign, notice: "Campaign saved. Sending isn’t wired in this prototype."
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def set_segment
    @segment = Segment.find(params[:segment_id])
  end

  def set_campaign
    @campaign = Campaign.find(params[:id])
  end

  def campaign_params
    params.require(:campaign).permit(:subject, :content)
  end

  def default_content(segment)
    angle = segment.campaign_angle
    "Hi there,\n\nWe put this together for the #{segment.name} audience (#{segment.contact_count} contacts).\n\n#{segment.description}\n\nWhy this angle: #{angle[:why]}\n\n— Horizon Travel"
  end
end
