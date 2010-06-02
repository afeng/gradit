class GamesController < ApplicationController
	
  before_filter :guest_filter
  before_filter :active_filter, :only => [:new_game]
  # GET /games
  # GET /games.xml
  def index
    #Note: .all does not yet work
    #@games = Game.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @games }
    end
  end

  # GET /games/1
  # GET /games/1.xml
 
  #Check if the answer was correct
  def ans
  	puts "ANSWER CHOSEN"
  	curr_user = Query.userByLogin("amber").first
  	puts curr_user
    #Find the current user, game, and word
    game = Query.gameById(params[:id].to_i).first
    puts game
    word = Query.wordByWord(game.currentword).first
    puts word
    
    @player = Query.gamePlayerByGame(game.key, curr_user.key).first
    
    #HARD CODE IN ANSWER UNTIL GAMEPLAYER/USER WORKS
    
    puts "looking for an answer.."
    choice = params[:answer].to_s
    puts choice
    word = Query.wordByWord(choice).first
    puts word
    definition = word.definition

	puts "current word"
	puts game.currentword
    #If correct answer
    if game.currentword == choice
      #Pick a new "current" word **NEED TO OPTIMIZE THIS**
      wordlist = Query.wordlistByName(game.wordlist_name.name).first 
      words = wordlist.WordFromWordlist($piql_env).to_a
      game.put("currentword", words[rand(words.length)].word)
      game.save
      
      puts "next word"
      puts game.currentword
      
      puts "saved the game"
      
      puts "gameplayer"
      puts @player
      #Add points to the user's score REMOVED UNTIL GAMEPLAYER WORKS
      oldscore = @player.score
      @player.put("score", java.lang.Integer.new(oldscore + 10))
      puts "newscore"
      puts @player.score
      @player.save($piql_env)
      
      puts "AJAX-ing"
      
      #AJAX update page to reflect changes in score, let the user know they are correct
      render :update do |page|
    	page[:ans_result].replace_html "Correct! Press next." #**NEED TO HAVE THIS REDIRECT, BUT IT DOESN'T WORK**
     	page[:player_score].replace_html "#{@player.score}"
     	page[:player_score].highlight
     	
        page["mult_choice_#{choice}"].replace_html "<b>#{choice} (definition: #{definition})</b>"
      end
      
    else #Incorrect answer
      puts "wrong answer"
      #Lower score 
     
      oldscore = @player.score
      puts "old score"
      puts oldscore
      @player.put("score", java.lang.Integer.new(oldscore - 5))
      puts "newscore"
      puts @player.score
      @player.save($piql_env)
      
     puts "saved the player"
      #Add wrong choice to the database for making questions "smarter"
      #How do associations work in rails? Which fields do we set?

      #NEED TO CHANGE THE FOLLOWING LINE
      w = WrongChoice.new
      w.put("word_word", word)
      #word.wrong_choices << w
      
      #Add defintion to incorrectly chosen word
      
      #AJAX update page to reflect changes in score, let user know they are incorrect
      render :update do |page|
        page[:ans_result].replace_html "Wrong, try again!"
	    page[:player_score].replace_html "#{@player.score}"
        page[:player_score].highlight
        page["mult_choice_#{choice}"].replace_html "#{choice} (definition: #{definition})"
      end
    end
  end
  
  #Displaying/picking questions
  def game_entry
  	puts 'GAME_ENTRY:'
    curr_user = Query.userByLogin("amber").first
    puts curr_user
    game = Query.gameById(params[:id].to_i).first
    @game_id = game.game_id
    puts game
    word = Query.wordByWord(game.currentword).first
    
    @player = Query.gamePlayerByGame(game.key, curr_user.key).first
    puts @player
    
    #HARD CODE USER IN UNTIL GAMEPLAYER/USER QUERY WORKS
    #@player = curr_user
    
    definition = word.definition
    
    #Get a random context for the word
    puts "finding contexts"
    @para = false
    contexts = Search.search(word.word).to_a #get context
    puts contexts
    puts contexts.length
    con = contexts.sort_by{ rand }.first
  	#con = contexts[rand(contexts.length)]
  	puts "THIS IS THE CONTEXT"
  	puts con
  	if(con)
  	  #Initialize paragraph, multiple choice settings
  	  @para_book = con.book_name;
      @para = con.before << con.wordline << con.after
      @para.gsub!(word.word, '___________') #underline the missing word
	  puts "THIS IS A LIST OF THE CHOICES"
      @mc = word.choices(global_entity_id)
      
      @mc_array = [@mc.choice1,@mc.choice2,@mc.choice3,@mc.choice4].sort_by{ rand }
    else
      #Find another word to use, no contexts
      wordlist = Query.wordlistByName(game.wordlist_name.name).first
      words = wordlist.WordFromWordlist($piql_env).to_a
      puts words
      word = words[rand(words.length)].word
      puts word
      game.currentword = word
      game.save
      redirect_to(:controller=> :games, :action=> :game_entry, :id => game.game_id)
    end    
    nexturl = url_for :controller => :games, :action => :game_entry, :id => game.game_id
    @disp = nexturl
  end

  def new_game
  	puts "hello? creating a new game"
    curr_user = Query.userByLogin("amber").first
    #Create the actual game object
    
	puts "global var"
	id = global_entity_id.to_i
	puts java.lang.Integer.new(id)
    game = Game.new
    game.put("game_id", java.lang.Integer.new(id))
    game.put("wordlist_name", Query.wordlistByName(params[:name]).first)
    game.put("finished", false)
    game.save
    
    puts game
    
    #Create Game Player for the user
    player = GamePlayer.new
    player.put("game_player_id", java.lang.Integer.new(global_entity_id.to_i))
    player.put("game", game)
    player.put("user_login", curr_user)
    player.put("score", java.lang.Integer.new(5))
    player.save($piql_env)
  	
    #Select a random word from the wordlist for the new "current" word
    puts "wordlist"
    wordlist = Query.wordlistByName(game.wordlist_name.name).first
    puts wordlist
    puts "finding words in wordlist"
    words = wordlist.WordFromWordlist($piql_env).to_a
    puts words
    word = words[rand(words.length)]
    
    #If there is a word
    if(word)
      game.put("currentword", word.word)
      game.save
      redirect_to(:controller=> :games, :action=> :game_entry, :id => game.game_id)
      return
    end
    flash[:notice] = "Wordlist has no words!"
    redirect_to :back
  end
  
  def active_filter
  	curr_user = Query.userByLogin("amber").first
    #Is the user currently in an active (not-over) game?
    active = curr_user.has_active_game
    if active
      flash[:notice] = "Oops! You already have an active game. Please quit the current game before you try to open a new one!"
      redirect_to :back
    end
    return true
  end
  
  def guest_filter
    #Allow guest access for playing games without login
    if User.guest_account_enabled
      if !authorized?
        self.current_user = Queries.userByLogin("amber")
        new_cookie_flag = (params[:remember_me] == "1")
        handle_remember_cookie! new_cookie_flag
      end
      return true
    else
      return false
    end
  end
  
  def quit_game
    #Quit the game - end the game and return to dashboard
    game = Query.gameById(params[:game_id].to_i).first
    game.put("finished", true)
    game.save
    redirect_to :controller => :dashboard
  end
  
  def vote_mc
  	puts "voting MC"
    #Up/down voting multiple choices
    vote = params[:vote] #true for up, false for down
    puts vote
    mc = Query.multipleChoiceById(params[:mc_id].to_i).first
    puts mc
    
    #Change multiple choice score accordingly
    mc.put("score", java.lang.Integer.new(mc.score + 1)) if vote == "up"
    mc.put("score", java.lang.Integer.new(mc.score - 1)) if vote == "down"
    mc.save($piql_env)
    
    #AJAX update the page to reflect changes
    render :update do |page|
      page[:mc_voting].replace_html "Your rating for this multiple choice question has been recorded."
      page[:mc_rating].replace_html "#{mc.score}"
      page[:mc_rating].highlight
    end
    
  end
  
  def next_word
  end
  
  def game_page
  end
  
  def curr_user_id
    user_id = 0
    user_id = current_user.id if(current_user)
    
    return user_id
  end
end
