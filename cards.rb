# This is the unfucked version of the Solitaire cipher used in Qoheleth. As the
# code was initially written to be difficult to read, it only cleans up so
# well, but this is offered both as an exercise, as well as proof that I at
# least kinda knew what I was doing :)
#
# Solitaire is a keystream cipher, which means that the key is an initial
# setting of a system, and as that system runs, it produces enough data (one
# byte) to encrypt one character (also one byte) at a time before the state of
# the system changes. Without knowing the original state of the system (a deck
# of cards, in this case), one cannot run the machine and get any worthwhile
# output. It's reasonably secure, as far as pen-and-paper algorithms go, and
# rather limited, so don't go about replacing good crypto with it!
#
# See the original page for more info:
# www.schneier.com/academic/solitaire/
#
# Cheers,
# Makyo

##### Constants

# The unicode characters representing the suits
SUITS = {
  :spades   => "\u2660",
  :clubs    => "\u2663",
  :hearts   => "\u2665",
  :diamonds => "\u2666"
}

# A regular expression for splitting a specified card into parts for figuring
# out values.
VALUE = Regexp.new(%r{
  (?<s>(                 # The 's' group contains the suit
    #{SUITS[:spades]}|   # Which can be one of the specified suits
    #{SUITS[:clubs]}|    # .
    #{SUITS[:hearts]}|   # .
    #{SUITS[:diamonds]}| # .
    A|B                  # Or our A/B jokers
  ))
  (?<v>(                 # The 'v' group contains the card's face value
    \d\d?|               # A number...
    [AJQKX]              # ...or Ace, Jack, Queen, King, or Joker (X)
  ))
}x)

# A map of card values to integer values; contains both suit starting points
# and values for face cards.
MAP_VALUES = {
  # Suit values: when a card is turned into a number, add the suit value to the
  # face value.
  SUITS[:clubs]   => 0,
  SUITS[:diamonds]=> 13,
  SUITS[:hearts]  => 26,
  SUITS[:spades]  => 39,
  # Values used for face cards.
  "A"=>1,
  "J"=>11,
  "Q"=>12,
  "K"=>13
}

# Map values back for face cards for printing decks.
INVERSE_VALUES = {
  1  => "A",
  11 => "J",
  12 => "Q",
  13 => "K"
}

##### Conversion functions

##
# Convert an integer into a represenation of a card (e.g: ♦2)

def int_to_card(i)
  # Find the suit first
  suit = :clubs    if i > MAP_VALUES[SUITS[:clubs]]
  suit = :diamonds if i > MAP_VALUES[SUITS[:diamonds]]
  suit = :hearts   if i > MAP_VALUES[SUITS[:hearts]]
  suit = :spades   if i > MAP_VALUES[SUITS[:spades]]

  # Subtract the suit, left with the face value
  i -= MAP_VALUES[SUITS[suit]]

  # If the value is in the map (e.g: AJQK), use that, otherwise use the value
  value = (INVERSE_VALUES.key?(i) ? INVERSE_VALUES[i] : i)

  return "#{SUITS[suit]}#{value}"
end


##
# Convert represenation of a card (e.g: ♦2) to an integer

def card_to_int(card)
  VALUE.match card do |m|
    # Check for jokers
    if m["v"] == "X"
      # If the value is X, the card is a joker, save the 'suit' (A or B)
      return m["s"]
    else
      # Otherwise, grab the suit and value and add them together
      suit = MAP_VALUES[m["s"]]
      value = (MAP_VALUES.key?(m["v"]) ? MAP_VALUES[m["v"]] : m["v"].to_i)
      return suit + value
    end
  end
end

##
# Process a deck from STDIN. Should be a list of cards in the form
# <suit><value> separated by a space. (e.g: ♦2 ♠8 ♠Q ♦8 ♣9 ♣Q...)

def process_deck(input)
  deck = input.split /\s+/
  raise("Bad deck: need 54 cards") if deck.length != 54
  return deck.collect {|card| card_to_int card}
end

##### Encryption helpers

##
# Move a card down in the deck

def move_down(deck, card)
  i = deck.index card
  if i != 53
    # If it's not the last card, shift the card's index down.
    deck[i], deck[i + 1] = deck[i + 1], deck[i]
    return deck
  else
    # If it's the last card, rotate the bottom card to the top.
    return [deck[-1]] + deck[0...-1]
  end
end

##
# Triple cut the deck: swap the section above the first joker with the section
# after the second joker.

def triple_cut(deck)
  # Find the jokers
  first, last = deck.index('A'), deck.index('B')

  # Assign first to whichever comes first in the deck, rather than A
  first, last = last, first if first > last

  # Build an array containing the three slices appropriately swapped, then
  # flatten it.
  return [
    deck[(last + 1)..-1],
    deck[first..last],
    deck[0...first]
  ].flatten
end

##
# Card cut the deck: look at the last card, get its value, and cut at that
# point in the deck, leaving that card last. If the last card is a joker, don't
# do anything.

def card_cut(deck)
  return deck if deck[-1].is_a? String

  # Get the last card
  last = deck.pop

  # Remove the number of cards from the top specified by last; the remainder of
  # deck is the second part of the cut
  first = deck.shift(last - 1)

  # Put the deck back together, swapping the two parts, and return.
  return deck + first + [last]
end

##
# Get one character from the keystring. This is where the gears turn.

def keystream(deck)
  # Move the A joker down once
  deck = move_down(deck,'A')

  # Move the B jokeer down twice
  deck = move_down(deck,'B')
  deck = move_down(deck,'B')

  # Triple cut
  deck = triple_cut(deck)

  # Card cut
  deck = card_cut(deck)

  # Look at the first card; count down that many, and use that card. If the
  # first card is a joker, use the value 53
  card = deck[deck[0].is_a?(Integer) ? deck[0] : 53]

  # If the card is a joker (value is a string), run the keystream again
  card, deck = keystream(deck) if card.is_a? String

  # Return the card (modulo 26) and the modified deck
  return card % 26, deck
end

##
# Run the cipher. As encryption and decryption are basically the same, do them
# in the same method, passing in a flag (true for encryption).

def go(deck, input, encrypt)
  # Strip all non-letters and make everything uppercase
  input = input.gsub(/[^a-zA-Z]/, '').upcase

  # If the length of the string isn't a multiple of 5, pad it with X until it is
  if input.length % 5 != 0
    input = input.ljust((input.length / 5 + 1) * 5, 'X')
  end

  # Start the (en|de)cryption
  output = ""
  input.each_byte do |c|
    key, deck = keystream deck

    # In both steps, we want to turn the input character into an int between 1
    # and 26. In encryption, we add the keystream character; in decryption, we
    # subtract it. Then get it back to a number between 1 and 26.
    # 64 is the ASCII value of 'A'.
    if encrypt then
      out_char = (c - 64 + key) % 26
    else
      out_char = (c - 64 - key) % 26
    end

    # Modulo subtraction leaves us with 0, but we want 26 in that case.
    out_char = 26 if out_char == 0

    # Add the output character to the output string.
    output << (out_char + 64).chr
  end

  # Split the output string into groups of five characters for display
  puts output.split(/(.{5})/).reject {|e| e==''}.join(' ')
end

##
# Create a randomized deck to be used as a 'key'

def create_deck
  # Add the non-jokers
  deck = (1..52).to_a

  # Translate them to cards
  deck.collect! {|i| int_to_card i}

  # Add the jokers
  deck += ['AX','BX']

  # Shuffle and print
  puts d.shuffle.join ' '
end

##
# Get the user's data for encrypting/decrypting

def run_cipher
  # Get the deck first
  print("deck> ")
  deck = process_deck(STDIN.gets.chomp)

  # Then get the text to en/decrypt
  print "text input> "
  text = STDIN.gets.chomp

  # Run the cipher. Any command line argument means to encrypt; no command line
  # argument means decrypt (the default for this project)
  go deck, text, ARGV.length > 0
end

if ARGV[0] == "shuffle"
  # If the user passed the argument 'shuffle', create a new key deck and quit.
  create_deck
  exit
else
  run_cipher
  exit
end
