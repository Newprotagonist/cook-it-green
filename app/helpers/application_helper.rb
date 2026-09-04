module ApplicationHelper
  # Incrémenter à chaque modification des icônes. Sans ce cache-buster, les
  # icônes mises à jour n'atteignent jamais les caches du navigateur, de l'OS
  # ni les notifications déjà envoyées.
  ICON_VERSION = 2

  def versioned_icon_path(filename)
    "#{asset_path(filename)}?v=#{ICON_VERSION}"
  end

  def macro_badge(macros, minimums = nil)
    parts = { "P" => macros.protein, "L" => macros.lipid,
              "G" => macros.carb, "F" => macros.fiber }
    safe_join(parts.map { |label, value|
      short = minimums && value < minimums[macro_key(label)].to_f - 0.05
      tag.span(class: "tabular-nums #{short ? 'text-rose-600 font-semibold' : 'text-stone-500'}") do
        safe_join([ tag.span(label, class: "text-stone-400"), " ", number_with_precision(value, precision: 1) ])
      end
    }, tag.span(" · ", class: "text-stone-300"))
  end

  def kcal(value) = number_with_delimiter(value.round, delimiter: " ")

  def grams(value) = "#{number_with_precision(value, precision: value.to_f % 1 == 0 ? 0 : 1)} g"

  private

  def macro_key(label)
    { "P" => :protein, "L" => :lipid, "G" => :carb, "F" => :fiber }.fetch(label)
  end
end
