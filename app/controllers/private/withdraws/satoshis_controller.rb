module Private
  module Withdraws
    class SatoshisController < ::Private::Withdraws::BaseController
      include ::Withdraws::Withdrawable
    end
  end
end
