require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Roman numerals" do              
  it "should add roman numerals correctly" do
    IV = RomanNumeral.get(4)
    res = IV + 5
    res.to_s.should == 'IX'    
  end   
end