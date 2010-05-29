
class Word
  include PIQLEntity
  has_and_belongs_to_many :wordlists
  has_many :contexts
  has_many :multiple_choices
  has_many :wrong_choices
  has_one :context_cache
  #attr_accessor :multiple_choices
  #attr_accessor :wrong_choices
  

  #adds to the list of attractive distractors associated with this
  #word. 
  #params: wrong_choice is a String object
  def add_wrong_choice(wrong_choice)
    wrong_word = Word.find_by_word(wrong_choice)
    existing_wrong_choices = self.wrong_choices 
    #attractive_distractors = existing_wrong_choices.map{|x| Word.find(x.wrong_choice_id)}

    #if !wrong_word.nil?
    if existing_wrong_choices.map{|x| x.wrong_choice_id}.include?(wrong_word.id)
      wc = existing_wrong_choices.select{|x| x.wrong_choice_id == wrong_word.id}.pop
      wc.count = wc.count + 1
      wc.save
    else
      w = WordList.new
      w.puts("wrong_choice_id", wrong_word.id)
      w.puts("count", 1)
      #NEED TO CHANGE THE FOLLOWING LINE
      self.wrong_choices << w
    end
  end
    
  def choices
    #mc = self.multiple_choices
    #mc = mc[rand(mc.length)]
    mclist = []
	# add wrong choices, if any

	#if (mc)
    #  if (mc.is_intersection)
    #    mclist = Intersect.find(mc.intersection_id).generateChoices
    #  else
    #    mclist = [ mc.choice1, mc.choice2, mc.choice3, mc.choice4 ]
    #  end
    #  if (self.wrong_choices.length > 0 && mclist.length<4)
    #    mclist = [self.wrong_choices[rand(4)]]
    #  end
    #end
	
    wrongchoices = self.wrong_choices
    
    if (wrongchoices.length > 0)
      #generate one attractive distractor if there are wrong choices (attractive distractors) available
      r1 = rand(wrongchoices.length)
      mclist << wrongchoices[r1]
      wrongchoices.delete_at(r1)
      if (wrongchoices.length>0)
        r2 = rand(wrongchoices.length)
        mclist << wrongchoices[r2]
        wrongchoices.delete_at(r2)
      end
    end
    
    allwords = Query.allWord
    allwords = aw.sort {rand}
    
    counter = 0
    while (mclist.length < 4)
      mclist << allwords[counter].word
      counter = counter + 1
    end
    #if (mc.nil? or mc.is_intersection) 
    mc_new = MultipleChoice.new
    mc_new.puts(":word_id", self.id)
    mc_new.puts("is_intersection", false)
    mc_new.puts("choice1", mclist[0])
    mc_new.puts("choice2", mclist[1])
    mc_new.puts("choice3", mclist[2])
    mc_new.puts("choice4", self.word)
    mc_new.puts("score", 0)
    #end
    #retlist = []
    #retlist << mclist[0] << mclist[1] << mclist[2] << self.word
    #return retlist.sort_by{ rand }
    return mc_new
  end    
end
