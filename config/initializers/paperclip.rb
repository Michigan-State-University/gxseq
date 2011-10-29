Paperclip.interpolates :filename_with_ext do |attachment, style|
  attachment.original_filename.gsub(/\.[^.]+$/, "."+attachment.instance.class.name.downcase)
end

Paperclip.interpolates :exp_class do |attachment, style|
  attachment.instance.experiment.class.name.underscore
end

Paperclip.interpolates :exp_id do |attachment, style|
  attachment.instance.experiment.id
end