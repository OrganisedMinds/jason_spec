require 'spec_helper'

describe "Examples from readme" do
  it "should do the most basic example" do
    %q({"first_name":"Jason","last_name":"Voorhees"}).should have_jason([:first_name,:last_name])
  end

  it "should do the root example" do
    %q({"movie":{"title":"Friday the 13th","release_year":"1980"}}).should have_jason(
      movie: [ :title, :release_year ]
    )
  end

  it "should do the object example" do
    class Movie
      attr_reader :title, :release_year
      def self.find(x)
        new
      end
      def initialize
        @title = "Friday the 13th"
        @release_year = "1980"
      end
    end

    my_movie = Movie.find(1)

    %q({"movie":{"title":"Friday the 13th","release_year":"1980"}}).should have_jason(
      { movie: { my_movie => [ :title, :release_year ] } }
    )
  end

  it "should do the basic Jason.spec example" do
    %q({"movies":[{"title":"Friday the 13th"},{"title":"Nightmare on Elm Street"}]}).should have_jason(
      movies: Jason.spec( type: Array, size: 2, each: [ :title ] )
    )
  end

  it "should do the final example" do
    json = %q({"user":{
        "user_name":"jason",
        "favorite_movies":[
          {"title":"Friday the 13th","id":1},
          {"title":"Nightmare on Elm Street","id":2}
        ]
      },
      "links":[
        { "href":"/users/2", "rel": "self" },
        { "href":"/users/2/movies", "rel": "favorite movies"}
      ]
    })

    json.should have_jason(
      user: {
        user_name: "jason",
        favorite_movies: Jason.spec(type: Array, each: [ :title, :id ])
      },
      links: Jason.spec(type: Array, each: [ :href, :rel ])
    )
  end
end

