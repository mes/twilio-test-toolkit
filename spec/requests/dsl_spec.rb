require 'spec_helper'

describe TwilioTestToolkit::DSL do
  before(:each) do
    @our_number = "2065551212"
    @their_number = "2065553434"
  end

  describe "ttt_call", type: :request do
    describe "basics" do
      before(:each) do
        @call = ttt_call(test_start_twilio_index_path, @our_number, @their_number)
      end

      it "should assign the call" do
        expect(@call).not_to be_nil
      end

      it "should have a sid" do
        expect(@call.sid).not_to be_blank
      end

      it "should default the method to post" do
        expect(@call.http_method).to eq(:post)
      end

      it "should have the right properties" do
        expect(@call.initial_path).to eq(test_start_twilio_index_path)
        expect(@call.from_number).to eq(@our_number)
        expect(@call.to_number).to eq(@their_number)
        expect(@call.is_machine).to be_falsey
      end
    end

    describe "with a sid, method and machine override" do
      before(:each) do
        @mysid = "1234567"
        @call = ttt_call(test_start_twilio_index_path, @our_number, @their_number, :call_sid => @mysid, :is_machine => true, :method => :get)
      end

      it "should have the right sid" do
        expect(@call.sid).to eq(@mysid)
      end

      it "should be a machine call" do
        expect(@call.is_machine).to be_truthy
      end

      it "should be a get call" do
        expect(@call.http_method).to eq(:get)
      end
    end

    describe "with a called and direction" do
      before(:each) do
        @direction = 'outbound-api'
        @call = ttt_call(test_start_twilio_index_path, @our_number, @their_number, :direction => @direction, :called => @their_number)
      end

      it "should have the right direction" do
        expect(@call.direction).to eq(@direction)
      end

      it "should have the right called number" do
        expect(@call.called).to eq(@their_number)
      end
    end
  end
end
