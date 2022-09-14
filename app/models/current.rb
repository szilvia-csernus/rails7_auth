# This class inherits from CurrentAttributes which allows us to keep all per-request attributes
# easily available to the whole system. Namely, we have access to current user during each 
# request to the server.

class Current < ActiveSupport::CurrentAttributes
  attribute :user
end