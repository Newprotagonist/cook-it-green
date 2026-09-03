require "test_helper"

class Nutrition::SolverTest < ActiveSupport::TestCase
  # Leviers synthétiques : un pur protéique, un pur lipidique, un pur glucidique.
  # Ils n'interfèrent pas entre eux, ce qui rend chaque assertion lisible.
  def lever(key, protein, lipid, carb, min, max)
    Nutrition::Solver::Lever.new(key: key, protein: protein / 100.0, lipid: lipid / 100.0,
                                 carb: carb / 100.0, min: min, max: max)
  end

  def pure_levers(max: 100)
    [ lever("prot", 100, 0, 0, 0, max),
      lever("lip",  0, 100, 0, 0, max),
      lever("gluc", 0, 0, 100, 0, max) ]
  end

  def macros_of(grams, levers)
    levers.reduce(Nutrition::Macros.zero) do |acc, l|
      g = grams.fetch(l.key, 0)
      acc + Nutrition::Macros.new(protein: l.protein * g, lipid: l.lipid * g,
                                  carb: l.carb * g, fiber: 0.0)
    end
  end

  test "tombe exactement sur une cible atteignable" do
    grams = Nutrition::Solver.new(step: 5)
      .solve(base: Nutrition::Macros.zero, levers: pure_levers,
             target: { protein: 35.0, lipid: 30.0, carb: 45.0 }).grams

    assert_equal 35, grams["prot"]
    assert_equal 30, grams["lip"]
    assert_equal 45, grams["gluc"]
  end

  test "préfère dépasser la cible que passer dessous" do
    # 36,3 g n'est pas atteignable au pas de 5 : le choix est 35 (-1,3) ou 40 (+3,7).
    # Sans pénalité asymétrique, 35 gagnerait puisqu'il est plus proche.
    # Les cibles étant des MINIMUMS, le solveur doit choisir 40.
    grams = Nutrition::Solver.new(step: 5)
      .solve(base: Nutrition::Macros.zero, levers: pure_levers,
             target: { protein: 36.3, lipid: 30.0, carb: 45.0 }).grams

    assert_equal 40, grams["prot"],
                 "le solveur a choisi le grammage inférieur alors que la cible est un minimum"
  end

  test "ne sort jamais des bornes, même si la cible est inatteignable" do
    levers = pure_levers(max: 60)
    grams = Nutrition::Solver.new(step: 5)
      .solve(base: Nutrition::Macros.zero, levers: levers,
             target: { protein: 200.0, lipid: 150.0, carb: 300.0 }).grams

    levers.each do |l|
      assert_operator grams[l.key], :<=, l.max, "#{l.key} dépasse sa borne haute"
      assert_operator grams[l.key], :>=, l.min, "#{l.key} passe sous sa borne basse"
    end
    assert_equal 60, grams["prot"], "un levier saturé doit se poser sur sa borne"
  end

  test "respecte une borne basse non nulle" do
    levers = [ lever("prot", 100, 0, 0, 40, 100),
               lever("lip", 0, 100, 0, 10, 100),
               lever("gluc", 0, 0, 100, 20, 100) ]
    grams = Nutrition::Solver.new(step: 5)
      .solve(base: Nutrition::Macros.zero, levers: levers,
             target: { protein: 5.0, lipid: 2.0, carb: 3.0 }).grams

    assert_equal 40, grams["prot"]
    assert_equal 10, grams["lip"]
    assert_equal 20, grams["gluc"]
  end

  test "déduit ce que la base apporte déjà" do
    base = Nutrition::Macros.new(protein: 20.0, lipid: 10.0, carb: 15.0, fiber: 5.0)
    grams = Nutrition::Solver.new(step: 5)
      .solve(base: base, levers: pure_levers,
             target: { protein: 35.0, lipid: 30.0, carb: 45.0 }).grams

    assert_equal 15, grams["prot"]
    assert_equal 20, grams["lip"]
    assert_equal 30, grams["gluc"]
  end

  test "refuse un nombre de leviers différent de trois" do
    assert_raises(ArgumentError) do
      Nutrition::Solver.new.solve(base: Nutrition::Macros.zero,
                                  levers: pure_levers.first(2),
                                  target: { protein: 10.0, lipid: 10.0, carb: 10.0 })
    end
  end
end
