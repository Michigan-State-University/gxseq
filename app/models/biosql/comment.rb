class Biosql::Comment < ActiveRecord::Base
  # comments have a primary key but also maintain a rank for their bioentry
  # comment is a reserved word in Oracle
  if(ActiveRecord::Base.connection.adapter_name.downcase =~/.*oracle.*/)
    set_table_name "comments"
    set_primary_key :comments_id
  else
    set_table_name "comment"
    set_primary_key :comment_id
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

