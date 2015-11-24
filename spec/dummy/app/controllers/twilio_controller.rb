class TwilioController < ApplicationController
  layout "twilio.layout"
  respond_to :xml
  
  def test_action
    @digits = params[:Digits]
  end    

  def test_call_status
    @call_status = params[:CallStatus]
  end
end
