module ApplicationHelper
  include Pagy::Frontend
  def time_ago_in_words_with_units(from_time)
    distance_in_seconds = ((Time.current - from_time) / 1.second).round
    case distance_in_seconds
    when 0..59
      "#{distance_in_seconds}s"
    when 59..3599
      "#{(distance_in_seconds / 60).round}m"
    when 3600..86399
      "#{(distance_in_seconds / 3600).round}h"
    when 86400..604799
      "#{(distance_in_seconds / 86400).round}d"
    when 604800..2678399
      "#{(distance_in_seconds / 604800).round}w"
    else
      "#{(distance_in_seconds / 31556952).round}y"
    end
  end
end
