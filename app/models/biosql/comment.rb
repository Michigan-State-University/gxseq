# == Schema Information
#
# Table name: comments
#
#  bioentry_id  :integer          not null
#  comment_text :text             not null
#  comments_id  :integer          not null, primary key
#  created_at   :datetime
#  rank         :integer          default(0), not null
#  updated_at   :datetime
#

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
