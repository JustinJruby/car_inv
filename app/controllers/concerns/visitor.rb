# A random identifier for the visitor, kept in a signed, permanent, httponly cookie (spec 006, research R2).
# It is the only identifier stored with a favorite (FR-002). It is not tied to an account and is never shown.
module Visitor
  extend ActiveSupport::Concern

  private
    # The visitor's identifier if one already exists, without creating one.
    def current_visitor_id
      cookies.signed[:visitor_id].presence
    end

    def visitor_id
      @visitor_id ||= current_visitor_id || create_visitor_id
    end

    def create_visitor_id
      id = SecureRandom.uuid
      cookies.permanent.signed[:visitor_id] = { value: id, httponly: true, same_site: :lax }
      id
    end
end
