ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "minitest/mock"
require_relative "test_helpers/session_test_helper"
require "stringio"

module ActiveSupport
  class TestCase
    # Pas de parallélisation : la suite partage un jeu de données lourd
    # (127 ingrédients, 48 plats) qu'il faudrait recharger dans chaque worker.
    parallelize(workers: 1)

    fixtures :all

    # Le vrai jeu de données, chargé une fois par processus et hors des
    # transactions de test. L'invariant central porte sur les 112 journées
    # de l'année : il ne se teste pas sur des fixtures partielles.
    def self.seed_reference_data!
      return if defined?(@@seeded) && @@seeded
      silence_output { load Rails.root.join("db/seeds.rb").to_s } if Ingredient.count.zero?
      @@seeded = true
    end

    def self.resolve_active_target!
      return if defined?(@@resolved) && @@resolved
      Menu::Recalculator.new(User.find_by!(email_address: "dev@example.com").nutrition_target).call if ResolvedDish.count.zero?
      @@resolved = true
    end

    def self.silence_output
      original = $stdout
      $stdout = StringIO.new
      yield
    ensure
      $stdout = original
    end
  end
end

# Tests qui ont besoin des tables de référence (ingrédients, objectifs, cibles).
class SeededTestCase < ActiveSupport::TestCase
  seed_reference_data!

  # L'utilisateur seedé par db/seeds.rb — identifié par email plutôt que
  # User.first, pour ne pas dépendre de l'ordre dans lequel les fixtures
  # (test/fixtures/users.yml) et la seed sont chargées.
  def owner = User.find_by!(email_address: "dev@example.com")
  def target = owner.nutrition_target
end

# Tests qui ont besoin en plus des grammages résolus.
class MenuTestCase < SeededTestCase
  resolve_active_target!

  def all_days
    Dish.distinct.pluck(:week_number).sort.flat_map { |n| Menu::Week.new(target, n).days }
  end
end
