require "test_helper"

class FavoriteTest < ActiveSupport::TestCase
  setup do
    @car = cars(:toyota)
    @visitor = SecureRandom.uuid
  end

  def build_favorite(**attrs)
    Favorite.new({ car: @car, visitor_id: @visitor, saved_at: Time.current }.merge(attrs))
  end

  test "visitor_id must be a UUID" do
    refute build_favorite(visitor_id: "not-a-uuid").valid?
    assert build_favorite(visitor_id: SecureRandom.uuid).valid?
  end

  test "saved_at is required" do
    refute build_favorite(saved_at: nil).valid?
  end

  test "removed_at may not be before saved_at" do
    refute build_favorite(saved_at: Time.current, removed_at: 1.day.ago).valid?
    assert build_favorite(saved_at: 2.days.ago, removed_at: 1.day.ago).valid?
  end

  test "one visitor has at most one active favorite per car" do
    build_favorite.save!
    duplicate = build_favorite
    refute duplicate.valid?
    assert_raises(ActiveRecord::RecordNotUnique) { build_favorite.save!(validate: false) }
  end

  test "saving again after a removal creates a new row" do
    first = build_favorite
    first.save!
    first.update!(removed_at: Time.current)
    assert build_favorite.save
    assert_equal 2, Favorite.where(car: @car, visitor_id: @visitor).count
  end

  test "the active scope leaves out removed favorites" do
    active = build_favorite
    active.save!
    removed = build_favorite(visitor_id: SecureRandom.uuid, saved_at: 2.days.ago, removed_at: 1.day.ago)
    removed.save!
    assert_includes Favorite.active, active
    assert_not_includes Favorite.active, removed
  end

  test "the 30-day window keeps only active favorites saved in the last 30 days" do
    recent = build_favorite(visitor_id: SecureRandom.uuid, saved_at: 3.days.ago)
    recent.save!
    old = build_favorite(visitor_id: SecureRandom.uuid, saved_at: 60.days.ago)
    old.save!
    removed_recent = build_favorite(visitor_id: SecureRandom.uuid, saved_at: 2.days.ago, removed_at: 1.day.ago)
    removed_recent.save!

    window = Favorite.active.saved_within(30.days.ago..Time.current)
    assert_includes window, recent
    assert_not_includes window, old
    assert_not_includes window, removed_recent
  end
end
