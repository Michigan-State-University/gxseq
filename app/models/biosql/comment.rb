class Comment < ActiveRecord::Base
  set_table_name "comment"
  set_primary_keys :comment_id,:rank
  if(ActiveRecord::Base.connection.adapter_name.downcase =~/.*oracle.*/)
    set_table_name "comments"
    set_primary_keys :comments_id,:rank
  end
  belongs_to :bioentry, :class_name  => "Bioentry"
end

# == Schema Information
#
# Table name: sg_comment
#
#  oid          :integer(38)     not null, primary key
#  rank         :integer(2)      not null
#  comment_text :text            not null
#  ent_oid      :integer(38)     not null
#

