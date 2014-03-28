class HelpController < ApplicationController

  def about
  end
  
  def tutorial
  end
  
  def manual
    send_file "doc/GS_manual.pdf", :type => 'application/pdf'
  end
  
  def faq
  end
  
  def index
  end
  
  def sitemap
  end
end