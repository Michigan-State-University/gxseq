# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Daley', :city => cities.first)


admin = (
  User.find_by_login(
    (APP_CONFIG[:admin_user] || "admin")
  ) || User.create(
    :login => (APP_CONFIG[:admin_user] || "admin"),
    :email => (APP_CONFIG[:admin_email] || "admin@admin.com"),
    :password => (APP_CONFIG[:admin_pass] || "secret")
  )
)

# Roles
admin_role = Role.find_or_create_by_name('admin')
Role.find_or_create_by_name('member')
Role.find_or_create_by_name('guest')
Role.find_or_create_by_name('api')

admin.roles << admin_role

public_grp = Group.public_group
public_grp.owner = admin
public_grp.save

## Find or create Tooltips
unless Tooltip.find_by_title('keyword_search')
  Tooltip.create(
    title: 'keyword_search',
    markup: 'textile',
    locale: 'en',
    content: %q(
h1. Tokens

Text is split on whitespace into multiple tokens.
Each token is queried with the terms you supply.
Leading and trailing punctuation is filtered from tokens.


h1. Terms

A Single Term is a single word such as 'test' or 'hello'.

A Phrase is a group of words surrounded by double quotes such as "hello dolly".


h2. Single Term Modifiers

Singe terms are matched against tokens. These modifiers control matches.

* "?":  single character wildcard - ('te?t' -- "text" or "test")
* "*":  multiple character wildcard -  ('test*' -- "test", "tests", "tester") 
* "*":  mid-word wildcard - ('te*t' -- "test", "testertest")
* "~":  fuzzy search character - ('roam~'  --  "foam" or "roams")
* "~1": optional edit distance 0,1,2 (default 2) - 'roam~1'

h2. Phrase Modifiers

Phrase terms are exact matches against tokens located together. Wildcards are not allowed with phrases. The number of tokens between a match can be controlled.

* "~" : proximity character - ("test text"~2 -- "test some more text")


h1. Boolean Operators

h2. AND

Default operator. Require both terms.

"test text" AND website

h2. OR

Require either one or both terms.

"test text" OR website

h2. NOT

Exclude items with term.

"test text" NOT website

h2. Grouping

Use parentheses to group clauses and form sub queries.

(test OR text) AND website
    )
  )
end