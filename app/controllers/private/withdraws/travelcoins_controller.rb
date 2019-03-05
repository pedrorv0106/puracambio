module Private
  module Withdraws
    class TravelcoinsController < ::Private::Withdraws::BaseController
      include ::Withdraws::Withdrawable
    end
  end
end
