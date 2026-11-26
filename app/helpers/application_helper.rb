module ApplicationHelper
  STATUS_BADGE_CLASSES = {
    "available" => "bg-emerald-50 text-emerald-700 ring-1 ring-inset ring-emerald-600/20",
    "reserved" => "bg-amber-50 text-amber-800 ring-1 ring-inset ring-amber-600/20",
    "sold" => "bg-slate-100 text-slate-600 ring-1 ring-inset ring-slate-500/20"
  }.freeze

  def car_status_badge(car)
    tag.span(car.status, class: "badge #{STATUS_BADGE_CLASSES.fetch(car.status, STATUS_BADGE_CLASSES["sold"])}")
  end
end
