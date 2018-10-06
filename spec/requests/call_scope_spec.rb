require 'spec_helper'

include Rails.application.routes.url_helpers

describe TwilioTestToolkit::CallScope, type: :request do
  before(:each) do
    @our_number = "2065551212"
    @their_number = "2065553434"
  end
  let(:default_request_params) do
    {
      :format => :xml,
      :From => "2065551212",
      :To => "2065553434",
      :AnsweredBy => "human",
      :CallStatus => "in-progress"
    }
  end

  describe "basics" do
    before(:each) do
      @call = ttt_call(test_start_twilio_index_path, @our_number, @their_number)
    end

    it "should be a CallScope" do
      expect(@call).to be_a(TwilioTestToolkit::CallScope)
    end

    it "should have the informational methods" do
      expect(@call).to respond_to(:current_path)
      expect(@call).to respond_to(:response_xml)
    end

    it "should have the right path" do
      expect(@call.current_path).to eq(test_start_twilio_index_path)
    end

    it "should have a response xml value" do
      expect(@call.response_xml).not_to be_blank
    end

    it "should have the right root call" do
      expect(@call).to respond_to(:root_call)
      expect(@call.root_call).to eq(@call)
    end
  end

  describe "redirect" do
    describe "success" do
      before(:each) do
        @call = ttt_call(test_redirect_twilio_index_path, @our_number, @their_number)
      end

      it "should have the redirect methods" do
        expect(@call).to respond_to(:has_redirect?)
        expect(@call).to respond_to(:has_redirect_to?)
        expect(@call).to respond_to(:follow_redirect)
        expect(@call).to respond_to(:follow_redirect!)
      end

      it "should have the right value for has_redirect?" do
        expect(@call).to have_redirect
      end

      it "should have the right values for has_redirect_to?" do
        expect(@call.has_redirect_to?("http://foo")).to be_falsey
        expect(@call.has_redirect_to?(test_start_twilio_index_path)).to be_truthy
        expect(@call.has_redirect_to?(test_start_twilio_index_path + ".xml")).to be_truthy    # Should force normalization
      end

      it "should follow the redirect (immutable version)" do
        # follow_redirect returns a new CallScope
        newcall = @call.follow_redirect

        # Make sure it followed
        expect(newcall.current_path).to eq(test_start_twilio_index_path)

        # And is not the same call
        expect(newcall.response_xml).not_to eq(@call.response_xml)
        # But it's linked
        expect(newcall.root_call).to eq(@call)

        # And we did not modify the original call
        expect(@call.current_path).to eq(test_redirect_twilio_index_path)
      end

      it "should follow the redirect (mutable version)" do
        # follow_redirect! modifies the CallScope
        @call.follow_redirect!

        # Make sure it followed
        expect(@call.current_path).to eq(test_start_twilio_index_path)
      end

      it "should submit default params on follow_redirect" do
        expect(Capybara.current_session.driver)
          .to receive(:post)
          .with("/twilio/test_start", hash_including(default_request_params))
          .and_call_original

        @call.follow_redirect
      end

      it "should consider options for follow_redirect!" do
        expect(Capybara.current_session.driver)
          .to receive(:post)
          .with("/twilio/test_start", hash_including(:CallStatus => "completed"))
          .and_call_original

        @call.follow_redirect!(call_status: "completed")
      end

      it "should consider options for follow_redirect" do
        expect(Capybara.current_session.driver)
          .to receive(:post)
          .with("/twilio/test_start", hash_including(:CallStatus => "completed"))
          .and_call_original

        @call.follow_redirect(call_status: "completed")
      end
    end

    describe "failure" do
      before(:each) do
        # Initiate a call that's not on a redirect - various calls will fail
        @call = ttt_call(test_say_twilio_index_path, @our_number, @their_number)
      end

      it "should have the right value for has_redirect?" do
        expect(@call).not_to have_redirect
      end

      it "should have the right values for has_redirect_to?" do
        expect(@call.has_redirect_to?("http://foo")).to be_falsey
        expect(@call.has_redirect_to?(test_start_twilio_index_path)).to be_falsey
        expect(@call.has_redirect_to?(test_start_twilio_index_path + ".xml")).to be_falsey
      end

      it "should raise an error on follow_redirect" do
        expect {@call.follow_redirect}.to raise_error 'No redirect'
      end

      it "should raise an error on follow_redirect!" do
        expect {@call.follow_redirect!}.to raise_error 'No redirect'
      end
    end
  end

  describe "say" do
    before(:each) do
      @call = ttt_call(test_say_twilio_index_path, @our_number, @their_number)
    end

    it "should have the expected say methods" do
      expect(@call).to respond_to(:has_say?)
    end

    it "should have the right values for has_say?" do
      expect(@call.has_say?("Blah blah")).to be_falsey
      expect(@call.has_say?("This is a say page.")).to be_truthy
      expect(@call.has_say?("This is")).to be_truthy      # Partial match
    end
  end

  describe "play" do
    before(:each) do
      @call = ttt_call(test_play_twilio_index_path, @our_number, @their_number)
    end

    it "should have the expected say play methods" do
      expect(@call).to respond_to(:has_play?)
    end

    context 'when exact_inner_match is not set' do
      it "should have the right values for has_say?" do
        expect(@call.has_play?("/path/to/a/different/audio/clip.mp3")).to be_falsey
        expect(@call.has_play?("/path/to/an/audio/clip.mp3")).to be_truthy
        expect(@call.has_play?("clip.mp3")).to be_truthy
      end
    end
    context 'when exact_inner_match is set' do
      it "should have the right values for has_say?" do
        expect(@call.has_play?("/path/to/a/different/audio/clip.mp3", exact_inner_match: true)).to be_falsey
        expect(@call.has_play?("/path/to/an/audio/clip.mp3", exact_inner_match: true)).to be_truthy
        expect(@call.has_play?("clip.mp3", exact_inner_match: true)).to be_falsey
      end
    end
  end

  describe "dial" do
    before(:each) do
      @call = ttt_call(test_dial_with_action_twilio_index_path, @our_number, @their_number)
    end

    it "should have the expected dial methods" do
      expect(@call).to respond_to(:has_dial?)
    end

    it "should have the right values for has_dial?" do
      expect(@call.has_dial?("911")).to be_falsey
      expect(@call.has_dial?("18001234567")).to be_truthy
      expect(@call.has_dial?("12345")).to be_truthy     # Partial match
    end

    it "should not match the dial action if there isn't one" do
      @call = ttt_call(test_dial_with_no_action_twilio_index_path, @our_number, @their_number)

      expect(@call.has_action_on_dial?("http://example.org:3000/call_me_back")).to eq false
    end

    it "should match the action on dial if there is one" do
      expect(@call.has_action_on_dial?("http://example.org:3000/call_me_back")).to be_truthy
    end

    it "should not match the action on dial if it's different than the one specified" do
      expect(@call.has_action_on_dial?("http://example.org:3000/dont_call")).to be_falsey
    end

    it "should dial a sip peer with the correct structure" do
      @call = ttt_call(test_dial_with_sip_twilio_index_path, @our_number, @their_number)
      @call.within_dial do |dial|
        expect(dial.has_sip?).to be_truthy
        dial.within_sip do |sip|
          expect(sip.has_uri?("18885551234@sip.foo.bar")).to be_truthy
          expect(sip.has_username_on_uri?("foo")).to be_truthy
          expect(sip.has_password_on_uri?("bar")).to be_truthy
        end
      end
    end
  end

  describe "hangup" do
    describe "success" do
      before(:each) do
        @call = ttt_call(test_hangup_twilio_index_path, @our_number, @their_number)
      end

      it "should have the expected hangup methods" do
        expect(@call).to respond_to(:has_hangup?)
      end

      it "should have the right value for has_hangup?" do
        expect(@call).to have_hangup
      end
    end

    describe "failure" do
      before(:each) do
        @call = ttt_call(test_start_twilio_index_path, @our_number, @their_number)
      end

      it "should have the right value for has_hangup?" do
        expect(@call).not_to have_hangup
      end
    end
  end

  describe "gather" do
    describe "success" do
      before(:each) do
        @call = ttt_call(test_start_twilio_index_path, @our_number, @their_number)
      end

      it "should have the expected gather methods" do
        expect(@call).to respond_to(:has_gather?)
        expect(@call).to respond_to(:within_gather)
        expect(@call).to respond_to(:gather?)
        expect(@call).to respond_to(:gather_action)
        expect(@call).to respond_to(:press)
        expect(@call).to respond_to(:speak)
        expect(@call).to respond_to(:speak_partially)
      end

      it "should have the right value for has_gather?" do
        expect(@call.has_gather?).to be_truthy
      end

      it "should have the right value for gather?" do
        # Although we have a gather, the current call scope is not itself a gather, so this returns false.
        expect(@call.gather?).to be_falsey
      end

      it "should fail on gather-scoped methods outside of a gather scope" do
        expect {@call.gather_action}.to raise_error 'Not a gather'
        expect {@call.press "1234"}.to raise_error 'Not a gather'
        expect {@call.speak "1234"}.to raise_error 'Not a gather'
        expect {@call.speak_partially "12","34"}.to raise_error 'Not a gather'
      end

      describe "gathering DTMF" do
        it "should gather" do
          # We should not have a say that's contained within a gather.
          expect(@call).not_to have_say("Please enter some digits.")

          # Now enter the gather block.
          @call.within_gather do |gather|
            # We should have a say here
            expect(gather).to have_say("Please enter some digits.")

            # We should be in a gather
            expect(gather.gather?).to be_truthy
            # And we should have an action
            expect(gather.gather_action).to eq(test_action_twilio_index_path)

            # And we should have the right root call
            expect(gather.root_call).to eq(@call)

            # Press some digits.
            gather.press "98765"
          end

          # This should update the path
          expect(@call.current_path).to eq(test_action_twilio_index_path)

          # This view says the digits we pressed - make sure
          expect(@call).to have_say "You entered 98765."
        end

        it "should gather without a press" do
          @call.within_gather do |gather|
            # Do nothing
          end

          # We should still be on the same page
          expect(@call.current_path).to eq(test_start_twilio_index_path)
        end

        it "should respond to the default finish key of hash" do
          @call.within_gather do |gather|
            gather.press "98765#"
          end
          expect(@call).to have_say "You entered 98765."
        end

        describe "with finishOnKey specified" do
          before(:each) do
            @call = ttt_call(test_gather_finish_on_asterisk_twilio_index_path, @our_number, @their_number)
          end

          it "should strip the finish key from the digits" do
            @call.within_gather do |gather|
              gather.press "98765*"
            end

            expect(@call).to have_say "You entered 98765."
          end

          it "should still accept the digits without a finish key (due to timeout)" do
            @call.within_gather do |gather|
              gather.press "98765"
            end

            expect(@call).to have_say "You entered 98765."
          end
        end
      end
      describe "gathering speech" do
        it "should gather" do
          # We should not have a say that's contained within a gather.
          expect(@call).not_to have_say("Please enter some digits.")

          # Now enter the gather block.
          @call.within_gather do |gather|
            # We should have a say here
            expect(gather).to have_say("Please enter some digits.")

            # We should be in a gather
            expect(gather.gather?).to be_truthy
            # And we should have an action
            expect(gather.gather_action).to eq(test_action_twilio_index_path)

            # And we should have the right root call
            expect(gather.root_call).to eq(@call)

            # Press some digits.
            gather.speak "98765"
          end

          # This should update the path
          expect(@call.current_path).to eq(test_action_twilio_index_path)

          # This view says the digits we pressed - make sure
          expect(@call).to have_say "You entered 98765."
        end
        it 'should post partial input' do

          # We should not have a say that's contained within a gather.
          expect(@call).not_to have_say('Please enter some digits.')

          # Now enter the gather block.
          @call.within_gather do |gather|
            # We should have a say here
            expect(gather).to have_say('Please enter some digits.')

            # We should be in a gather
            expect(gather.gather?).to be_truthy
            # And we should have an action
            expect(gather.gather_action).to eq(test_action_twilio_index_path)

            # And we should have the right root call
            expect(gather.root_call).to eq(@call)

            expect(Capybara.current_session.driver)
              .to receive(:post)
              .with(
                "/twilio/test_partial_result_callback",
                hash_including(
                  default_request_params.merge(
                    StableSpeechResult: '987',
                    UnstableSpeechResult: '65'
                  )
                )
              )
              .and_call_original

            # Press some digits.
            gather.speak_partially '987', '65'
          end
        end
      end
    end

    describe "failure" do
      before(:each) do
        @call = ttt_call(test_say_twilio_index_path, @our_number, @their_number)
      end

      it "should have the right value for has_gather?" do
        expect(@call.has_gather?).to be_falsey
      end

      it "should have the right value for gather?" do
        expect(@call.gather?).to be_falsey
      end

      it "should fail on within_gather if there is no gather" do
        expect {@call.within_gather do |gather|; end}.to raise_error 'No el in scope'
      end

      it "should fail on gather-scoped methods outside of a gather scope" do
        expect {@call.gather_action}.to raise_error 'Not a gather'
        expect {@call.press "1234"}.to raise_error 'Not a gather'
      end
    end
  end

  describe "record" do
    before(:each) do
      @call = ttt_call(test_record_twilio_index_path, @our_number, @their_number)
    end

    it "should have the expected say record methods" do
      expect(@call).to respond_to(:has_record?)
    end

    it "should have the right action for record"  do
      expect(@call.has_action_on_record?("http://example.org:3000/record_this_call")).to be_truthy
    end

    it "should have the right maxLength for record"  do
      expect(@call.has_max_length_on_record?("20")).to be_truthy
      expect(@call.has_max_length_on_record?(20)).to be_truthy
    end

    it "should have the right finishOnKey for record"  do
      expect(@call.has_finish_on_key_on_record?("*")).to be_truthy
    end
  end

  describe "conditional handling on call_status" do
    it "should default to in progress" do
      @call = ttt_call(test_call_status_twilio_index_path, @our_number, @their_number)
      expect(@call).to have_say "Your call is in progress."
    end

    it "should respond differently to a ringing call" do
      @call = ttt_call(test_call_status_twilio_index_path, @our_number, @their_number, :call_status => 'ringing')
      expect(@call).to have_say "Your call is ringing."
    end
  end
end
