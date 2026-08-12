module ApplicationHelper
  def flash_class(type)
    case type.to_sym
    when :notice then "flash-notice"
    when :alert then "flash-alert"
    else "flash-notice"
    end
  end

  def recent_activities(contact, limit: 3)
    contact.events.sort_by(&:occurred_at).reverse.first(limit)
  end
end
