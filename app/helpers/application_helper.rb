module ApplicationHelper
  def strength_dot_class(strength)
    case strength
    when "strong" then "bg-teal"
    when "moderate" then "bg-ink/50"
    else "bg-ink/25"
    end
  end

  def flash_class(type)
    case type.to_sym
    when :notice then "flash-notice"
    when :alert then "flash-alert"
    else "flash-notice"
    end
  end

  def insight_label(kind)
    {
      "trend" => "Trend",
      "split" => "Split",
      "risk" => "Watch",
      "opportunity" => "Opportunity"
    }[kind] || kind.to_s.capitalize
  end
end
