class GamesController < ApplicationController
  # GET /games
  # GET /games.xml
  def index
    @games = Game.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @games }
    end
  end

  # GET /games/1
  # GET /games/1.xml
  def show
    @game = Game.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @game }
    end
  end
  
  def game_entry
  	word = params[:current_word]
  	
  	contexts = Search.search(word) #get context
  	a = contexts.first
  	if(!a)
  		flash[:notice] = "Sorry, word not found in context"
  		return
  	end
  	@para = a[0] << a[1] << a[2]
  	@para.gsub(word, '___________') #underline the missing word
  	
  	@words = Array.new
  	#randomize 4 other vocabulary words
  	for i in 1..4
  		@words << Word.find(i)
  	end

  	
  end

  def new_game
  	user_id = 0
  	user_id = current_user.id if(current_user)
  	
  	game = Game.new(:wordlist_id => params[:id], :finished => false, :winner_id => nil)
  	game.save
  	
  	player = GamePlayer.new(:game_id => game.id, :user_id => user_id, :score => 0)
  	
  	word = game.wordlist.words.first
  	if(word)
  		redirect_to(:controller=> :games, :action=> :game_entry, :id => game.id, :current_word => word.word)
  		return
  	end
  	flash[:notice] = "Wordlist has no words!"
  	redirect_to :back
  end
  
  def game_page
  end
  	
  # GET /games/new
  # GET /games/new.xml
  def new
    @game = Game.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @game }
    end
  end

  # GET /games/1/edit
  def edit
    @game = Game.find(params[:id])
  end

  # POST /games
  # POST /games.xml
  def create
    @game = Game.new(params[:game])

    respond_to do |format|
      if @game.save
        flash[:notice] = 'Game was successfully created.'
        format.html { redirect_to(@game) }
        format.xml  { render :xml => @game, :status => :created, :location => @game }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @game.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /games/1
  # PUT /games/1.xml
  def update
    @game = Game.find(params[:id])

    respond_to do |format|
      if @game.update_attributes(params[:game])
        flash[:notice] = 'Game was successfully updated.'
        format.html { redirect_to(@game) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @game.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /games/1
  # DELETE /games/1.xml
  def destroy
    @game = Game.find(params[:id])
    @game.destroy

    respond_to do |format|
      format.html { redirect_to(games_url) }
      format.xml  { head :ok }
    end
  end
end
