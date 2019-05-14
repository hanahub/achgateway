$: << File.join(File.expand_path(File.dirname(__FILE__)), "../", "util")
require 'validator'
require 'authorizenet'

include AuthorizeNet::API

module Authorizenet
  class Transaction

    module Type
      CREDIT = 'refundTransaction'
      DEBIT = 'authCaptureTransaction'
    end

    attr_reader :amount, :request_type, :bank_account

    def initialize(request_type, amount, bank_account)
      @amount = amount
      Validator.presence(:amount, @amount)
      @request_type = request_type
      Validator.presence(:request_type, @request_type)
      Validator.is_equal(:request_type, @request_type, [Type::CREDIT, Type::DEBIT])
      @bank_account = bank_account
    end

    def build_request
      request = CreateTransactionRequest.new
      request.transactionRequest = TransactionRequestType.new()
      request.transactionRequest.amount = @amount
      request.transactionRequest.transactionType = @request_type
      request.transactionRequest.payment = PaymentType.new
      request.transactionRequest.payment.bankAccount = @bank_account
      request.transactionRequest.order = OrderType.new
      request.transactionRequest.order.description = @bank_account.memo
      request.transactionRequest.billTo = CustomerAddressType.new
      request.transactionRequest.billTo.firstName = @bank_account.nameOnAccount.split(" ")[0]
      request.transactionRequest.billTo.lastName = @bank_account.nameOnAccount.split(" ")[1]
      request.transactionRequest.customer = CustomerDataType.new
      request.transactionRequest.customer.id = @bank_account.sub_merchant_id
      return request
    end

  end
end
