# Wacktrace

Make your stacktraces wack! Insert arbitrary content into the call stack if that is, for some reason, something you want to do. Who am I to judge?

```
# in example.rb:
Wacktrace.add_to_stack([
  ['Fire in the disco!', 1, '🔥🕺 '],
  ['Fire in the Taco Bell!', 2, '🔥🌮 '],
  ['Fire in the disco!', 3, '🔥🕺 '],
  ['Fire in the gates of hell!', 4, '🔥😈 '],
]) do
  raise "High Voltage!"
end
```

```
$ ruby example.rb
example.rb:25:in `block in <main>': High Voltage! (RuntimeError)
	from /Users/kevin/.rvm/gems/ruby-3.0.0/gems/wacktrace-0.1.0/lib/wacktrace.rb:49:in `block in add_to_stack'
	from 🔥🕺 :1:in ` Fire in the disco︕ '
	from 🔥🌮 :2:in ` Fire in the Taco Bell︕'
	from 🔥🕺 :3:in ` Fire in the disco︕'
	from 🔥😈 :4:in ` Fire in the gates of hell︕'
	from /Users/kevin/.rvm/gems/ruby-3.0.0/gems/wacktrace-0.1.0/lib/wacktrace.rb:50:in `add_to_stack'
	from example.rb:19:in `<main>'
```

Amaze your friends! Annoy your coworkers! Ok, it's mostly that second one! But maybe someone has a good use for this, like inserting warnings into stack traces:

```
Traceback (most recent call last):
	14: from example.rb:47:in `<main>'
	13: from example.rb:35:in `dangerous_method'
	12: from /Users/kevin/.rvm/gems/ruby-2.7.2/gems/wacktrace-0.1.0/lib/wacktrace.rb:60:in `add_to_stack_from_lyrics'
	11: from /Users/kevin/.rvm/gems/ruby-2.7.2/gems/wacktrace-0.1.0/lib/wacktrace.rb:50:in `add_to_stack'
	10: from !:in ` '
	 9: from !:1:in `  ––––––––––––––––– WARNING︕ ––––––––––––––––––––––'
	 8: from !:2:in ` ｜ If you hit an error here， you ＊really＊ need ｜'
	 7: from !:3:in ` ｜ to go over to the FooBarBaz admin panel and    ｜'
	 6: from !:4:in ` ｜ clean up the Spleem that were erroniously      ｜'
	 5: from !:5:in ` ｜ created․  If you don’t do that， bad things    ｜'
	 4: from !:6:in ` ｜ will happen︕                                  ｜'
	 3: from !:7:in `  ––––––––––––––––––––––––––––––––––––––––––––––––––'
	 2: from /Users/kevin/.rvm/gems/ruby-2.7.2/gems/wacktrace-0.1.0/lib/wacktrace.rb:49:in `block in add_to_stack'
	 1: from example.rb:44:in `block in dangerous_method'
example.rb:30:in `real_dangerous_method': terrible error (RuntimeError)
```

### How's it work?

Sketchily! It's a set of wack stack hacks. The basic idea is that we just set up a series of methods like:

```
def a; b; end
def b; c; end
def c; actual_function; end
```

But to dynamically generate methods, you'd usually reach for `define_method`. Unfortunately, methods defined with `define_method` don't actually show up in call stacks because that'd be too easy. Instead we'll use `eval("def #{method_name};#{next_method_name};end")`. And, as a bonus, `eval` lets us pass in a filename and line number for stack trace purposes!

But to avoid having a hundred methods in the global namespace like `baby_shark_do_do_do_do_do_do_do`, we'll `Class.new`-up a temporary class and then `instance_eval` on that.

But now we're stuck with underscore-laden method names. We're not gonna stand for that kinda limitation. We're gonna reach for the sun and slap the face of god. We'll take arbitrary text and replace all the invalid characters like `"` and `@` with unicode near-equivalents like `＂` and `＠`. Because `def Cthulhu R'lyeh wgah'nagl fhtagn` isn't a valid ruby method, but the visually-identical `def Cthulhu R’lyeh wgah’nagl fhtagn` is!

Other fun tricks:

- Detect which direction ruby is printing stack traces today (it's newest-first on a gibbous or waxing moon, and newest-last the rest of the month)
- Deal with duplicate method names by padding them with non-breaking-spaces
- Prepend all methods with non-breaking spaces so ruby doesn't get confused by methods that start with capital letters

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'wacktrace'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install wacktrace

## Usage

To have full(ish) control over the stack trace contents, call `add_to_stack` and give it a block. That block will be run with the lines you provide in its call stack:

```
Wacktrace.add_to_stack([
  ['method name 1', 123, 'file name 1'],
  ['method name 2', 123, 'file name 2'],
  ['method name 3', 123, 'file name 3'],
]) do
  puts caller_locations
  # Prints out:
  #  file name 1:123:in ` method name 1'
  #  file name 2:456:in ` method name 2'
  #  file name 3:789:in ` method name 3'
end
```

If you want a quicker way to shove a bunch of text (like a warning, comment, or classic poem on the fleeting nature of mankind's greatest achievements), you can use `add_to_stack_from_lyrics` with a single newline-delimited string:

```
lyrics = "I met a traveller from an antique land,
Who said—“Two vast and trunkless legs of stone
Stand in the desert... Near them, on the sand,
Half sunk a shattered visage lies, whose frown,
And wrinkled lip, and sneer of cold command,
Tell that its sculptor well those passions read
Which yet survive, stamped on these lifeless things,
The hand that mocked them, and the heart that fed;
And on the pedestal!, these words appear:
My name is Ozymandias, King of Kings;
Look on my Works, ye Mighty, and despair!
Nothing beside remains. Round the decay
Of that colossal Wreck, boundless and bare
The lone and level sands stretch far away.”"
Wacktrace.add_to_stack_from_lyrics(lyrics, 'Percy Bysshe Shelley') { raise "Suck it, Horace Smith." }
```

...which will result in...

```
ruby example.rb
example.rb:17:in `block in <main>': Suck it, Horace Smith. (RuntimeError)
	from /Users/kevin/.rvm/gems/ruby-3.0.0/gems/wacktrace-0.1.0/lib/wacktrace.rb:56:in `block in add_to_stack'
	from Percy Bysshe Shelley:in ` I met a traveller from an antique land，'
	from Percy Bysshe Shelley:1:in ` Who said—“Two vast and trunkless legs of stone'
	from Percy Bysshe Shelley:2:in ` Stand in the desert․․․ Near them， on the sand，'
	from Percy Bysshe Shelley:3:in ` Half sunk a shattered visage lies， whose frown，'
	from Percy Bysshe Shelley:4:in ` And wrinkled lip， and sneer of cold command，'
	from Percy Bysshe Shelley:5:in ` Tell that its sculptor well those passions read'
	from Percy Bysshe Shelley:6:in ` Which yet survive， stamped on these lifeless things，'
	from Percy Bysshe Shelley:7:in ` The hand that mocked them， and the heart that fed;'
	from Percy Bysshe Shelley:8:in ` And on the pedestal︕， these words appear：'
	from Percy Bysshe Shelley:9:in ` My name is Ozymandias， King of Kings;'
	from Percy Bysshe Shelley:10:in ` Look on my Works， ye Mighty， and despair︕'
	from Percy Bysshe Shelley:11:in ` Nothing beside remains․ Round the decay'
	from Percy Bysshe Shelley:12:in ` Of that colossal Wreck， boundless and bare'
	from Percy Bysshe Shelley:13:in ` The lone and level sands stretch far away․”'
	from /Users/kevin/.rvm/gems/ruby-3.0.0/gems/wacktrace-0.1.0/lib/wacktrace.rb:57:in `add_to_stack'
	from /Users/kevin/.rvm/gems/ruby-3.0.0/gems/wacktrace-0.1.0/lib/wacktrace.rb:67:in `add_to_stack_from_lyrics'
	from example.rb:17:in `<main>'
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/wacktrace. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/wacktrace/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Wacktrace project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/wacktrace/blob/main/CODE_OF_CONDUCT.md).
