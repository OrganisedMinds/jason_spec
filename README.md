# jason_spec

Write specs for JSON without writing JSON or data-structures

<a href="http://www.flickr.com/photos/frogdna/5534481247/" title="Friday the 13th - Jason Mask Replica by frogDNA, on Flickr"><img src="http://farm6.staticflickr.com/5094/5534481247_361aa64980.jpg" width="375" height="500" alt="Friday the 13th - Jason Mask Replica"></a>

## Install

`gem install jason_spec`

or, in your Gemfile, possibly in the test group

`gem "jason_spec"`


## Usage

### Test by specification

Jason spec is designed to test json by specifying the desired result. This
means you should not type or create any JSON; or even data structures.

The following snippet:

```ruby
%q({"first_name":"Jason","last_name":"Voorhees"}).should have_jason([:first_name,:last_name])
```

would result in a match. The supplied JSON has a `:first_name` and a
`:last_name` key - that's all we wanted to know.

Off course, you can also specify your root object:

```ruby
%q({"movie":{"title":"Friday the 13th","release_year":"1980"}}).should have_jason(
  movie: [ :title, :release_year ]
)
```

### Test by object

Now it is also nice to test the actual values; you can do this by supplying an
object in the specifications key, like so:

```ruby
# assuming ActiveRecord or so

my_movie = Movie.find(x)

%q({"movie":{"title":"Friday the 13th","release_year":"1980"}}).should have_jason(
  { movie: { my_movie => [ :title, :release_year ] } }
)
```

This will check the values of the JSON against the value of `my_movie.title`
and `my_movie.release_year`

### Test by enhanced specification

Now; that is all pretty nice and dandy, but what about complex(er) JSON
structures? How can I test those, without supplying huge structures as a
specification?

**Jason::Spec** to the resque:

```ruby
%q({"movies":[{"title":"Friday the 13th"},{"title":"Nightmare on Elm Street"}]}).should have_jason(
  movies: Jason.spec( type: Array, size: 2, each: [ :title ] )
)
```

Basicly we are saying; the JSON should have a `movies` key, it should hold
an `Array` with a size of `2` and each element should have a `title` key.

Off course you should combine all of it to make full use of the potential:

```ruby
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
```

## State

Alpha - not even released to RubyGems.org.

The final example might just work, see `spec/readme_spec.rb`

## Contributing to jason_spec

* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet.
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it.
* Fork the project.
* Start a feature/bugfix branch.
* Commit and push until you are happy with your contribution.
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

## Copyright

Copyright (c) 2013 OrganisedMinds GmbH. See LICENSE.txt for
further details.

