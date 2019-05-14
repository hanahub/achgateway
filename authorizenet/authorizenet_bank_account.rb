$: << File.join(File.expand_path(File.dirname(__FILE__)), "../", "util")
require 'validator'
require 'authorizenet'

include AuthorizeNet::API

module Authorizenet
  class BankAccount < BankAccountType

    attr_reader :accountType, :routingNumber, :accountNumber, :nameOnAccount, :echeckType, :memo, :sub_merchant_id

    def initialize(options)
      @accountType = options["account_type"]
      Validator.presence(:accountType, @accountType)
      Validator.is_equal(:accountType, @accountType, ['savings', 'checking'])
      @routingNumber = options["aba"]
      Validator.presence(:routingNumber, @routingNumber)
      Validator.is_aba(:routingNumber, @routingNumber)
      @accountNumber = options["account_number"]
      Validator.presence(:accountNumber, @accountNumber)
      Validator.is_numeric_string(:accountNumber, @accountNumber)
      @nameOnAccount = options["name"]
      Validator.presence(:name, @nameOnAccount)
      @memo = options["memo"] ||= ""
      @sub_merchant_id = options["sub_merchant_id"]
      Validator.is_not_longer_than(:sub_merchant_id, @sub_merchant_id, 25)
    end

  end
end
