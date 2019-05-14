module Authorizenet
  class ResponseCode
    def self.to_text(status)
      return "Approved" if status == "1"
      return "Declined" if status == "2"
      return "Error"    if status == "3"
      return "Held"     if status == "4"
      return "Status Not Available"
    end
  end
end
