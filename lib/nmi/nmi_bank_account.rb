$: << File.join(File.expand_path(File.dirname(__FILE__)), "../", "util")
require 'validator'

module Nmi
  class BankAccount

    attr_reader :account_type, :checkaba, :checkaccount, :checkname

    def initialize(options)
      @account_type = options["account_type"]
      Validator.presence(:account_type, @account_type)
      Validator.is_equal(:account_type, @account_type, ["savings", "checking"])
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
      bank_account_info["checkname"] = @checkname
      bank_account_info["checkaba"] = @checkaba
      bank_account_info["checkaccount"] = @checkaccount
      bank_account_info["account_type"] = @account_type
      return bank_account_info
    end

  end
end
