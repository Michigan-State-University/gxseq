When /^I run thor (\w+):(\w+) with "(.*)"$/ do |namespace,method,args|
  args = args.split
  args.unshift(method.to_sym)
  klass = ("Thor::Sandbox::"+namespace.camelize).constantize
  Dir.mkdir(::Rails.root.to_s+"/tmp/aruba" ) unless Dir.exists?(::Rails.root.to_s+"/tmp/aruba" )
  Dir.chdir(::Rails.root.to_s+"/tmp/aruba" ) do
    with_redirected_stdout do
      klass.start args
    end
  end
end
 
Then /^the last output should match "([^"]*)"$/ do |expected|
  mock_output.should =~ /#{expected}/
end