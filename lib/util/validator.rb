module Validator

  def self.presence(sym, val)
    raise "Must include :" + sym.to_s + " in initialization" if val.nil?
  end

  def self.is_numeric_string(sym, val)
    raise "Attribute " + sym.to_s + " must be in string form" if !(val.is_a? String)
    is_numeric_string = true
    val.chars.each do |char|
      is_numeric_string = false if !["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"].include?(char)
    end
    raise "Attribute " + sym.to_s + " must be a string with numberic characters" if !is_numeric_string
  end

  def self.is_equal(sym, val, compare_list)
    if !compare_list.include?(val)
      list = ""
      compare_list.each { |item| list << " '" << item << "'," }
      raise "Attribute " + sym.to_s + " must be one of the following:" + list[0..list.size-2]
    end
  end

  def self.is_more_than(sym, val, min)
    return if val.nil?
    raise "Attribute #{sym.to_s} must be greater than #{min}" if val.to_i < min
  end

  def self.is_less_than(sym, val, max)
    return if val.nil?
    raise "Attribute #{sym.to_s} must be less than #{max}" if val.to_i > max
  end

  def self.is_not_longer_than(sym, val, max_length)
    return if val.nil?
    raise "Attribute #{sym.to_s} is longer than #{max_length}" if val.length > max_length
  end

  def self.is_aba(sym, val)
    raise "Attribute " + sym.to_s + " must be a string that is 9 digits long and starts with 0, 1, 2 or 3" if !valid_aba_format?(val)
  end

  private

  def self.valid_aba_format?(aba)
    return false if !(aba.is_a? String)
    return false if !(aba.size == 9)
    return false if self.valid_aba_first_digit?(aba.chars.first) == false
    return true
  end

  def self.valid_aba_first_digit?(digit)
    return false if !(["0", "1", "2", "3", "4"].include?(digit))
    return true
  end

end
