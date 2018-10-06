class TwilioController < ApplicationController
  layout "twilio.layout"
  respond_to :xml

  def test_action
    @digits = params[:Digits] || params[:SpeechResult]
  end

  def test_call_status
    @call_status = params[:CallStatus]
  end

  def test_partial_result_callback
    render text: 'OK'
  end
end
