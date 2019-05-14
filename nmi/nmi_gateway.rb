$: << File.join(File.expand_path(File.dirname(__FILE__)), "./", "nmi")

require 'nokogiri'
require 'payment_gateway'
require 'nmi_transaction'
require 'nmi_bank_account'
require 'nmi_response_code'
require 'data_converter'
require 'http_portal'

module ACH
  class NmiGateway < PaymentGateway

    PROD_URL = "https://secure.networkmerchants.com/api/"
    TRANSACTION_METHOD = "transact.php"
    CHECK_TRANS_STATUS_METHOD = "query.php"

    def initialize(username, password, logger = Logger.new('/dev/null'))
      @username = username
      @password = password
      @logger = logger
    end

    def authenticate_gateway
      auth_info = {}
      auth_info["username"] = @username
      auth_info["password"] = @password
      return auth_info
    end

    def credit(options)
      conduct_transaction(options, Nmi::Transaction::Type::CREDIT)
    end

    def debit(options)
      conduct_transaction(options, Nmi::Transaction::Type::DEBIT)
    end

    def transaction_status(remote_id)
      hash_trans = {}
      hash_trans["transaction_id"] = remote_id
      request_query_string = build_query(hash_trans)
      @logger.info {"#{DateTime.now} nmigateway: transaction_status transaction_id: #{remote_id}" }
      post_request(transaction_status_url, request_query_string)

      return ERROR_MESSAGES[:NO_RESPONSE] if invalid_response(request_response)
      status = parse_transaction_settlment_status(generate_doc(request_response))
      return ERROR_MESSAGES[:NOT_FOUND] if status.empty?

      return status
    end

    private

    def transaction_url
      PROD_URL + TRANSACTION_METHOD
    end

    def transaction_status_url
      PROD_URL + CHECK_TRANS_STATUS_METHOD
    end

    def conduct_transaction(options, request_type)
      if !Validator.valid_aba_format?(options["aba"])
        return invalid_transaction_response_report(REQUEST_STATUS_CODE[:ERROR],
                                                   ERROR_MESSAGES[:INVALID_ABA])
      end

      echeck_transaction = Nmi::Transaction.new(options).build_request(request_type)
      bank_account = Nmi::BankAccount.new(options).build_request

      request_query_string = build_query(bank_account.merge(echeck_transaction))
      @logger.info {"#{DateTime.now} nmigateway: request name: #{options["name"]}" }
      post_request(transaction_url, request_query_string)

      begin
        return send_report(DataConverter.query_string_to_hash(request_response))
      rescue StandardError => error
        @logger.error { "#{DateTime.now} nmigateway conduct_transaction: #{error}" }
        return invalid_transaction_response_report(REQUEST_STATUS_CODE[:ERROR], ERROR_MESSAGES[:NO_RESPONSE])
      end
      return send_report(DataConverter.query_string_to_hash(request_response))
    end

    def send_report(response)
      if response["response"] == Nmi::ResponseCodes::APPROVED
        return transaction_response_report(REQUEST_STATUS_CODE[:OK],
                                           response["transactionid"],
                                           transaction_status(response["transactionid"]))
      end

      return invalid_transaction_response_report(REQUEST_STATUS_CODE[:ERROR], response["responsetext"])
    end

    def build_query(info)
      DataConverter.hash_to_query_string(authenticate_gateway.merge(info))
    end

    def post_request(url, body)
      @portal = Http::Portal.new
      @portal.send(url, body)
    end

    def request_response
      @portal.response
    end

    def invalid_response(response)
      response == {} || response == nil
    end

    def generate_doc(xml)
      Nokogiri::XML.parse(xml)
    end

    def parse_transaction_settlment_status(xml_response)
      return xml_response.xpath("//condition").text
    end

  end

 end
