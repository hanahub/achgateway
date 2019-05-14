$: << File.join(File.expand_path(File.dirname(__FILE__)), "../")

require 'payment_gateway'
require 'authorizenet'
require_relative 'authorizenet_transaction'
require_relative 'authorizenet_response_code'
require_relative 'authorizenet_bank_account'

include AuthorizeNet::API

module ACH
  class AuthorizeNetGateway < PaymentGateway

    def initialize(username, password, gateway_env, logger = Logger.new('achgateway_log.txt'))
      @username = username
      @password = password
      @gateway_env = gateway_env
      @logger = logger
    end

    def authenticate_gateway
      return Transaction.new(@username, @password, :gateway => @gateway_env)
    end

    def debit(options)
      conduct_transaction(options, Authorizenet::Transaction::Type::DEBIT)
    end

    def transaction_status(remote_id)
      request = GetTransactionDetailsRequest.new
      request.transId = remote_id
      @logger.info {"#{DateTime.now} authorizenetgateway: transaction_status request: #{remote_id}"}

      response = get_transaction_status(request)


      if response != nil
        if response.messages.resultCode == MessageTypeEnum::Ok
          return response.transaction.transactionStatus
        else
          @logger.debug {"#{DateTime.now} authorizenetgateway: transaction_status response: #{response.messages.messages[0].text}"}
          return response.messages.messages[0].text
        end
      end

      return ERROR_MESSAGES[:NO_RESPONSE]
    end

    def create_sub_merchant(description, merchant_customer_id, phone, bank_account_name = "", aba= "", account_number= "")
      request = CreateCustomerProfileRequest.new
      request.profile = CustomerProfileType.new(merchant_customer_id, description, nil ,nil, nil)
      @logger.info {"#{DateTime.now} authorizenetgateway: create_sub_merchant request: #{request}"}

      response = authenticate_gateway.create_customer_profile(request)
      @logger.info {"#{DateTime.now} authorizenetgateway: create_sub_merchant response: #{response}"}

      if response.messages.resultCode != MessageTypeEnum::Ok
        raise "Failed to create a new customer profile."
      end
      return response
    end

    private

    def conduct_transaction(options, request_type)
      if !Validator.valid_aba_format?(options["aba"])
        return invalid_transaction_response_report(REQUEST_STATUS_CODE[:ERROR], ERROR_MESSAGES[:INVALID_ABA])
      end

      bank_account = Authorizenet::BankAccount.new(options)
      request = Authorizenet::Transaction.new(request_type, options["amount"], bank_account).build_request
      @logger.info {"#{DateTime.now} authorizenetgateway: conduct_transaction request: #{request}, name: #{bank_account.nameOnAccount}"}

      response = post_transaction_request(request)

      return send_report(response)
    end

    def send_report(response)
      if response != nil && response.transactionResponse != nil
        log_transaction_response(response, response.transactionResponse)
        if response.messages.resultCode == MessageTypeEnum::Ok
          return process_transaction(response)
        else
          if response.transactionResponse != nil && response.transactionResponse.errors != nil
            return invalid_transaction_response_report(REQUEST_STATUS_CODE[:ERROR], response.transactionResponse.errors.errors[0].errorText)
          end
        end
      end

      return invalid_transaction_response_report(REQUEST_STATUS_CODE[:ERROR], ERROR_MESSAGES[:NO_RESPONSE])
    end

    def process_transaction(response)
      if transaction_posted?(response)
        transaction_status = transaction_status(response.transactionResponse.transId)
        return transaction_response_report(REQUEST_STATUS_CODE[:OK], response.transactionResponse.transId, transaction_status)
      end
      return invalid_transaction_response_report(REQUEST_STATUS_CODE[:ERROR], Authorizenet::ResponseCode.to_text(response.transactionResponse.responseCode))
    end

    def transaction_posted?(response)
      valid_transaction_response?(response.transactionResponse.responseCode) && (response.transactionResponse.messages != nil)
    end

    def valid_transaction_response?(response_code)
      response_code == "1" || response_code == "4"
    end

    def post_transaction_request(request)
      authenticate_gateway.create_transaction(request)
    end

    def get_transaction_status(request)
      authenticate_gateway.get_transaction_details(request)
    end

    def log_transaction_response(response, trans_response)
      trans_id = trans_response.transId unless trans_response.transId.nil?
      api_response_code = response.messages.messages[0].code unless response.messages.nil?
      error_code = trans_response.errors.errors[0].errorCode unless trans_response.errors.nil?
      log_message = "#{DateTime.now} authorizenetgateway: response: #{response}, trans_id: #{trans_id}, api_response_code: #{api_response_code}"
      if trans_response.errors != nil
        log_message += ", error_code: #{trans_response.errors.errors[0].errorCode}"
      end
      @logger.info {log_message}
    end

  end
end
