Before('@thor') do
  # Load all our thor files
  # Class constants are placed under Thor::Sandbox::
  thor_files = Dir.glob(::Rails.root.to_s+"/lib/tasks"+'**/*.thor').delete_if { |x| not File.file?(x) }
  thor_files.each do |f|
    Thor::Util.load_thorfile(f)
  end
end