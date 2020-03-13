# frozen_string_literal: true

class TrivialConsumer < ApplicationConsumer
  def consume
    Karafka.logger.info "Consumed following message: #{params}"
  end
end
