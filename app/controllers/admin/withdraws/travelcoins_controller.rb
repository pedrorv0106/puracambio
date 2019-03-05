module Admin
  module Withdraws
    class TravelcoinsController < ::Admin::Withdraws::BaseController
      load_and_authorize_resource :class => '::Withdraws::Travelcoin'

      def index
        start_at = DateTime.now.ago(60 * 60 * 24)
        @one_travelcoins = @travelcoins.with_aasm_state(:accepted).order("id DESC")
        @all_travelcoins = @travelcoins.without_aasm_state(:accepted).where('created_at > ?', start_at).order("id DESC")
      end

      def show
      end

      def update
        @ether.process!
        redirect_to :back, notice: t('.notice')
      end

      def destroy
        @ether.reject!
        redirect_to :back, notice: t('.notice')
      end
    end
  end
end
