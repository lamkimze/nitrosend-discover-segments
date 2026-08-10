class CampaignsController < ApplicationController
  before_action :set_segment, only: %i[new create]
  before_action :set_campaign, only: %i[show update]

  def new
    @campaign = @segment.campaigns.build(
      subject: default_subject(@segment),
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

  def default_subject(segment)
    case segment.slug
    when /japan/ then "Japan, at your pace — curated routes for travellers like you"
    when /luxury/ then "Quiet luxury escapes — villas, drivers, and tables worth dressing for"
    when /budget/ then "Smart travel without the markup — deals matched to how you explore"
    when /engaged/ then "You’re one of our most curious travellers — here’s what’s next"
    else "A trip shaped around how you travel"
    end
  end

  def default_content(segment)
    "Hi there,\n\nWe put this together for the #{segment.name} audience (#{segment.contact_count} contacts).\n\n#{segment.description}\n\n— Horizon Travel"
  end
end
