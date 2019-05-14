$: << File.join(File.expand_path(File.dirname(__FILE__)), "../", "util")
require 'validator'

module Gms
  class Transaction

    module Type
      CREDIT = "C"
      DEBIT = "D"
    end

    module Status
      PENDING = "Pending"
      APPROVED = "Approved",
      DECLINED = "Declined",
      ERROR = "Error"
    end

    attr_reader :amount

    def initialize(options)
      @amount = options["amount"]
      Validator.presence(:amount, @amount)
      Validator.is_more_than(:amount, @amount, 1)
    end

    def build_request(transaction_type)
      trans_info = {}
      trans_info["amount"] = @amount
      trans_info["trans_type"] = transaction_type
      trans_info["transaction_id"] = ""
      return trans_info
    end

  end
end
