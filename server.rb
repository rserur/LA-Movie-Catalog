require 'sinatra'
require 'pg'

def db_connection

  begin

    connection = PG.connect(dbname: 'movies')

    yield(connection)

  ensure

    connection.close

  end

end

# actors list
get '/actors' do

  # check for page
  @page = params[:page].to_i

  @search_term = params[:query]

  # if a search term is entered, search for terms in actor or character names
  if @search_term != nil

    db_connection do |conn|

      @actors = conn.exec("SELECT actors.id, actors.name, cast_members.character FROM actors JOIN
      cast_members ON cast_members.actor_id = actors.id WHERE actors.name ILIKE '%#{@search_term.to_s}%'
      OR cast_members.character ILIKE '%#{@search_term.to_s}%'")
      @actors = @actors.values

    end

    # otherwise, just load all actors, limited to 20 per page
  else

    db_connection do |conn|

      @actors = conn.exec('SELECT actors.id, actors.name, COUNT(cast_members.actor_id) AS MovieCount FROM cast_members
      JOIN actors ON cast_members.actor_id = actors.id GROUP BY actors.name, actors.id ORDER BY actors.name
      ASC LIMIT 20 OFFSET $1', [@page * 20])
      @actors = @actors.values

    end

  end

  erb :actors

end

# actor information
get '/actors/:id' do

  # load by ID
  @query = params[:id]

  db_connection do |conn|

    @roles = conn.exec('SELECT actors.name, movies.title, cast_members.character, movies.id
    FROM actors JOIN cast_members ON actors.id = cast_members.actor_id JOIN movies ON
    cast_members.movie_id = movies.id WHERE actors.id = $1', [@query])
    @roles = @roles.values

  end

  @roles = @roles.to_a

  erb :actor

end

# movies list
get '/movies' do

  @page = params[:page].to_i

  # check for sorting selection
  @order = params[:order].to_s

  @search_term = params[:query]

  # sort by year
  if @order == "year"

    db_connection do |conn|

      @movies = conn.exec('SELECT movies.id, movies.title, movies.year, movies.rating,
      genres.name, studios.name FROM movies JOIN genres ON genres.id = movies.genre_id
      JOIN studios ON studios.id = movies.studio_id ORDER BY movies.year ASC LIMIT 20 OFFSET $1', [@page * 20])
      @movies = @movies.values

    end

    # sort by rating
  elsif @order == "rating"

    db_connection do |conn|

      @movies = conn.exec('SELECT movies.id, movies.title, movies.year, movies.rating,
      genres.name, studios.name FROM movies JOIN genres ON genres.id = movies.genre_id
      JOIN studios ON studios.id = movies.studio_id WHERE movies.rating IS NOT NULL
      ORDER BY movies.rating DESC LIMIT 20 OFFSET $1', [@page * 20])
      @movies = @movies.values

    end

    # otherwise, default sort is alphabetical
  else

    db_connection do |conn|

      @movies = conn.exec('SELECT movies.id, movies.title, movies.year, movies.rating,
      genres.name, studios.name, movies.synopsis FROM movies JOIN genres ON genres.id = movies.genre_id
      JOIN studios ON studios.id = movies.studio_id ORDER BY movies.title ASC LIMIT 20 OFFSET $1', [@page * 20])
      @movies = @movies.values

    end

  end

  # check for search terms and search movie titles and synopses
  if @search_term != nil

    db_connection do |conn|

      @movies = conn.exec("SELECT movies.id, movies.title, movies.year, movies.rating,
      genres.name, studios.name, movies.synopsis FROM movies JOIN genres ON genres.id = movies.genre_id
      JOIN studios ON studios.id = movies.studio_id WHERE movies.title ILIKE '%#{@search_term.to_s}%' OR movies.synopsis ILIKE '%#{@search_term.to_s}%'")
      @movies = @movies.values

    end

    erb :movies

  end

  @movies = @movies.to_a

  erb :movies

end

# movie information
get '/movies/:id' do

  @query = params[:id]

  # actor's movies
  db_connection do |conn|

    @movie = conn.exec('SELECT movies.id, movies.title, movies.year, movies.rating,
    genres.name, studios.name FROM movies JOIN genres ON genres.id = movies.genre_id
    JOIN studios ON studios.id = movies.studio_id WHERE movies.id = $1', [@query])
    @movie = @movie.values

  end

  # actor's roles
  db_connection do |conn|

    @roles = conn.exec('SELECT actors.name, cast_members.character, actors.id
    FROM actors JOIN cast_members ON actors.id = cast_members.actor_id JOIN movies ON
    cast_members.movie_id = movies.id WHERE movies.id = $1', [@query])
    @roles = @roles.values

  end

  @roles = @roles.to_a

  erb :movie

end
