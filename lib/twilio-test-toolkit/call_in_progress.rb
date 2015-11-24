require "twilio-test-toolkit/call_scope"

module TwilioTestToolkit
  # Models a call
  class CallInProgress < CallScope
    attr_reader :options
    attr_reader :sid, :initial_path, :http_method
    attr_reader :from_number, :to_number
    attr_reader :is_machine, :called, :direction

    # Initiate a call. Options:
    # * :method - specify the http method of the initial api call
    # * :call_sid - specify an optional fixed value to be passed as params[:CallSid]
    # * :is_machine - controls params[:AnsweredBy]
    def initialize(initial_path, from_number, to_number, options = {})
      default_options = {
        :method     => :post,
        :direction  => 'inbound',
        :is_machine => false
      }

      @options = default_options.merge(options)

      # Save our variables for later
      @initial_path = initial_path
      @from_number  = from_number
      @to_number    = to_number
      @is_machine   = @options[:is_machine]
      @called       = @options[:called]
      @direction    = @options[:direction]
      @http_method  = @options[:method]

      # Generate an initial call SID if we don't have one
      if (options[:call_sid].nil?)
        @sid = UUIDTools::UUID.random_create.to_s
      else
        @sid = options[:call_sid]
      end

      # We are the root call
      self.root_call = self

      # Create the request
      request_for_twiml!(@initial_path, @options)
    end

  end
end
