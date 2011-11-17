#encoding: utf-8

class BorrowerMailer < ActionMailer::Base
  default from: "bibliothek@japanologie.uni-tuebingen.de"

  def overdue_reminder(user)
    @name = user.name
    @lendings = user.lendings.overdue
    mail :to => user.email, :subject => "Bücher sind überfallig" 
  end
end
