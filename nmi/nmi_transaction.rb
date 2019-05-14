$: << File.join(File.expand_path(File.dirname(__FILE__)), "../", "util")
require 'validator'

module Nmi
  class Transaction

    module Type
      CREDIT = "credit"
      DEBIT = "sale"
    end

    attr_reader :amount, :name, :sub_merchant_id, :memo

    def initialize(options)
      @amount = options["amount"]
      Validator.presence(:amount, @amount)
      Validator.is_less_than(:amount, @amount, 1500)
      @name = options["name"]
      Validator.presence(:name, @name)
      @sub_merchant_id = options["sub_merchant_id"]
      @memo = options["memo"]
    end

    def build_request(request_type)
      trans_info = {}
      trans_info["amount"] = @amount
      trans_info["payment"] = "check"
      trans_info["type"] = request_type
      trans_info["first_name"] = @name.split(" ")[0]
      trans_info["last_name"] = @name.split(" ")[1]
      trans_info["merchant_defined_field_1"] = @sub_merchant_id
      trans_info["order_description"] = @memo
      return trans_info
    end

  end
end
