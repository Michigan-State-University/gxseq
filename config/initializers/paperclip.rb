Paperclip.interpolates :filename_with_ext do |attachment, style|
  attachment.original_filename.gsub(/\.[^.]+$/, "."+attachment.instance.class.name.downcase)
end

Paperclip.interpolates :sample_class do |attachment, style|
  attachment.instance.sample.class.name.underscore
end

Paperclip.interpolates :sample_id do |attachment, style|
  attachment.instance.sample.id
end

Paperclip.interpolates :sample_name do |attachment, style|
  attachment.instance.sample.name
end

Paperclip.interpolates :blast_name do |attachment, style|
  attachment.instance.name
end

Paperclip.interpolates :assembly_name do |attachment, style|
  attachment.instance.assembly_name
end