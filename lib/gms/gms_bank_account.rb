$: << File.join(File.expand_path(File.dirname(__FILE__)), "../", "util")
require 'validator'

module Gms
  class BankAccount

    attr_reader :account_type, :checkaba, :checkaccount, :checkname

    ACCOUNT_TYPE = { "checking" => "C",
                     "savings"  => "S" }

    def initialize(options)
      @account_type = ACCOUNT_TYPE[options["account_type"]]
      Validator.presence(:account_type, @account_type)
      @checkaba = options["aba"]
      Validator.presence(:checkaba, @checkaba)
      Validator.is_aba(:checkaba, @checkaba)
      @checkaccount = options["account_number"]
      Validator.presence(:checkaccount, @checkaccount)
      Validator.is_numeric_string(:checkaccount, @checkaccount)
      @checkname = options["name"]
      Validator.presence(:checkname, @checkname)
    end

    def build_request
      bank_account_info = {}
      bank_account_info["name"] = @checkname
      bank_account_info["bank_route"] = @checkaba
      bank_account_info["bank_acct"] = @checkaccount
      bank_account_info["account_type"] = @account_type
      bank_account_info["address"] = ""
      bank_account_info["city"] = ""
      bank_account_info["state"] = ""
      bank_account_info["zip"] = ""
      return bank_account_info
    end

  end
end
