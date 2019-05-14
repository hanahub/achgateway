$: << File.join(File.expand_path(File.dirname(__FILE__)), "../")

require 'payment_gateway'
require 'util/http_portal'
require 'data_converter'
require_relative 'gms_transaction'
require_relative 'gms_bank_account'
require_relative 'gms_response_code'

module ACH
  class GmsGateway < PaymentGateway

    include Gms::Parameters

    PROD_URL = "https://www.gms-operations.com/webservices/ACHPayorService/ACHPayorService.asmx/"
    TRANSACTION_METHOD = "InstantResponseACH"
    REFUND_METHOD = "InstantResponseRefund"
    CHECK_TRANS_STATUS_METHOD = "InstantTransactionResponseByID"

    def initialize(api_id, api_key, gms_id, logger = Logger.new('achgateway_log.txt'))
      @api_id = api_id
      @api_key = api_key
      @gms_id = gms_id
      @logger = logger
    end

    def authenticate_gateway
      auth_info = {}
      auth_info["api_id"] = @api_id
      auth_info["api_key"] = @api_key
      auth_info["gms_id"] = @gms_id
      return auth_info
    end

    def debit(options)
      conduct_transaction(options, Gms::Transaction::Type::DEBIT)
    end

    def refund(options)
      refund_transaction(options)
    end

    def transaction_status(remote_id)
      hash_trans = {}
      hash_trans["id"] = remote_id
      hash_trans["type"] = "ACH"
      request_query_string = build_query(hash_trans)
      @logger.info {"#{DateTime.now} gmsgateway: transaction_status id: #{remote_id}" }
      post_request(transaction_status_url, request_query_string)
      hash_response = xml_to_hash(request_response)

      begin
        if hash_response[ONE_TIME_TRANS] != nil
          @logger.info {"#{DateTime.now} gmsgateway: transaction_status id: #{remote_id} : response:\n#{request_response}\n" }
          return hash_response[ONE_TIME_TRANS][STATE]
        else
          @logger.debug {"#{DateTime.now} gmsgateway: transaction_status id: #{remote_id} : response:\n#{request_response}\n" }
          return hash_response
        end
      rescue StandardError => error
        @logger.error { "#{DateTime.now} gmsgateway: transaction_status id: #{remote_id} :  #{error}" }
        return ERROR_MESSAGES[:NO_RESPONSE]
      end
    end

    private

    def transaction_url
      PROD_URL + TRANSACTION_METHOD
    end

    def refund_url
      PROD_URL + REFUND_METHOD
    end

    def transaction_status_url
      PROD_URL + CHECK_TRANS_STATUS_METHOD
    end

    def conduct_transaction(options, transaction_type)
      if !Validator.valid_aba_format?(options["aba"])
        return invalid_transaction_response_report(REQUEST_STATUS_CODE[:ERROR],
                                                   ERROR_MESSAGES[:INVALID_ABA])
      end

      echeck_transaction = Gms::Transaction.new(options).build_request(transaction_type)
      bank_account = Gms::BankAccount.new(options).build_request

      @logger.info {"#{DateTime.now} gmsgateway: conduct_transaction request name: #{options["name"]}" }
      post_request(transaction_url, build_query(bank_account.merge(echeck_transaction)))

      begin
        send_report(xml_to_hash(request_response))
      rescue StandardError => error
        @logger.error { "#{DateTime.now} gmsgateway: conduct_transaction #{error}" }
        return invalid_transaction_response_report(REQUEST_STATUS_CODE[:ERROR], ERROR_MESSAGES[:NO_RESPONSE])
      end
    end

    def refund_transaction(options)
      post_request(refund_url, build_query(options))

      begin
        send_report(xml_to_hash(request_response))
      rescue StandardError => error
        @logger.error { "#{DateTime.now} gmsgateway: refund_transaction #{error}" }
        return invalid_transaction_response_report(REQUEST_STATUS_CODE[:ERROR], ERROR_MESSAGES[:NO_RESPONSE])
      end
    end

    def build_query(payload)
      DataConverter.hash_to_query_string(authenticate_gateway.merge(payload))
    end

    def post_request(url, body)
      @portal = Http::Portal.new
      @portal.send(url, body)
    end

    def request_response
      @portal.response
    end

    def send_report(response)
      if response[ONE_TIME_TRANS] != nil
        if response[ONE_TIME_TRANS][STATE] == Gms::Transaction::Status::PENDING
          return transaction_response_report(REQUEST_STATUS_CODE[:OK],
                                             response[ONE_TIME_TRANS][TRAN_ID],
                                             response[ONE_TIME_TRANS][STATE])
        end
      end
      return invalid_transaction_response_report(REQUEST_STATUS_CODE[:ERROR], response)
    end

    def xml_to_hash(xml)
      begin
        return Hash.from_xml(xml.to_s)
      rescue StandardError => error
        @logger.error { "#{DateTime.now} gmsgateway: xml_to_hash #{error}" }
        return xml
      end
    end

  end
end
