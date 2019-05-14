module ACH
  class PaymentGateway

    REQUEST_STATUS_CODE = {
      :OK => 'Ok',
      :ERROR => 'Error'
    }

    ERROR_MESSAGES = {
      :NO_RESPONSE => "No response from payment processor, please try again",
      :INVALID_ABA => "Invalid ABANumber",
      :NOT_FOUND => "Not found"
    }

    def transaction_response_report(status, transaction_id, transaction_status)
      return {:status => status,
              :transaction_id => transaction_id,
              :transaction_status => transaction_status}
    end

    def invalid_transaction_response_report(status, message)
      return {:status => status,
              :message => message}
    end
  end
end
