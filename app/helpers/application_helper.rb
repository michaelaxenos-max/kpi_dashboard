module ApplicationHelper
  def nav_link_class(path)
    active = current_page?(path)
    base = "flex items-center gap-3 px-3 py-2 rounded-lg text-sm font-medium transition-colors"
    active ? "#{base} bg-accent text-white" : "#{base} text-dim hover:text-ink hover:bg-elevated"
  end

  def kpi_color_class(pct)
    return "bg-elevated text-faint" if pct.nil?

    case pct
    when 120.. then "bg-emerald-100 text-emerald-700 ring-1 ring-emerald-300 dark:bg-emerald-500/20 dark:text-emerald-300 dark:ring-emerald-500/40"
    when 100..120 then "bg-green-100 text-green-700 dark:bg-green-500/20 dark:text-green-300"
    when 80..100 then "bg-yellow-100 text-yellow-700 dark:bg-yellow-500/20 dark:text-yellow-300"
    when 60..80 then "bg-orange-100 text-orange-700 dark:bg-orange-500/20 dark:text-orange-300"
    else "bg-red-100 text-red-700 dark:bg-red-500/20 dark:text-red-300"
    end
  end

  def kpi_bar_color(pct)
    return "bg-divider" if pct.nil?

    case pct
    when 120.. then "bg-emerald-500"
    when 100..120 then "bg-green-500"
    when 80..100 then "bg-yellow-500"
    when 60..80 then "bg-orange-500"
    else "bg-red-500"
    end
  end

  def project_count_color(count)
    return "text-faint" if count.nil? || count == 0
    count >= 4 ? "text-green-600 dark:text-green-400" :
    count == 3 ? "text-yellow-600 dark:text-yellow-400" :
                 "text-red-500 dark:text-red-400"
  end

  def fmt_hours(h)
    total_minutes = (h.to_f * 60).round
    hh = total_minutes / 60
    mm = total_minutes % 60
    return "#{mm}m"  if hh.zero?
    return "#{hh}h"  if mm.zero?
    "#{hh}h #{mm}m"
  end

  def kpi_badge(pct)
    return content_tag(:span, "—", class: "text-faint text-xs") if pct.nil?

    label = pct >= 120 ? "#{pct.round}% ★" : "#{pct.round}%"
    content_tag(:span, label, class: "text-xs font-semibold px-2 py-0.5 rounded-full #{kpi_color_class(pct)}")
  end
end
