require 'sinatra'
require 'pg'
require 'pry'

def db_connection
  begin
    connection = PG.connect(dbname: 'movies')

    yield(connection)

  ensure
    connection.close
  end
end

# get '/movies' do

#   @movies = get_movies

#   erb :index

# end

get '/actors' do

  db_connection do |conn|
    @actors = conn.exec('SELECT id, name FROM actors ORDER BY name')
    @actors = @actors.values
  end

  @actors = @actors.to_a

  @page = params[:page].to_i

  index = @page.to_i * 20
  @actors = @actors.slice(index,20)

  erb :actors

end

get '/actors/:id' do

  @query = params[:id]



   db_connection do |conn|
    @roles = conn.exec('SELECT actors.name, movies.title, cast_members.character
      FROM actors JOIN cast_members ON actors.id = cast_members.actor_id JOIN movies ON
      cast_members.movie_id = movies.id WHERE actors.id = $1', [@query])

    @roles = @roles.values
  end

  @roles = @roles.to_a

  erb :actor

end

get '/movies' do

 db_connection do |conn|
    @movies = conn.exec('SELECT movies.id, movies.title, movies.year, movies.rating,
      genres.name, studios.name FROM movies JOIN genres ON genres.id = movies.genre_id
      JOIN studios ON studios.id = movies.studio_id')
    @movies = @movies.values
  end

  @movies = @movies.to_a

  @page = params[:page].to_i

  index = @page.to_i * 20
  @movies = @movies.slice(index,20)

  erb :movies

end

get '/movies/:id' do

  @query = params[:id]

   db_connection do |conn|
    @movie = conn.exec('SELECT movies.id, movies.title, movies.year, movies.rating,
      genres.name, studios.name FROM movies JOIN genres ON genres.id = movies.genre_id
      JOIN studios ON studios.id = movies.studio_id WHERE movies.id = $1', [@query])

    @movie = @movie.values
  end

    db_connection do |conn|
    @roles = conn.exec('SELECT actors.name, cast_members.character
      FROM actors JOIN cast_members ON actors.id = cast_members.actor_id JOIN movies ON
      cast_members.movie_id = movies.id WHERE movies.id = $1', [@query])

    @roles = @roles.values
  end

  @roles = @roles.to_a


  erb :movie

end
