#! /usr/bin/env coffee
#
# TODO: write some doc (like the deal with the spell module)
#
# 3rd party modules
#
spell = require 'spell'
_ = require 'underscore'
#
# utilities
print = console.log
put = (msg...) ->
  process.stdout.write "#{msg}"
  return
#
# -------------------------------------------------- #
#       Defining all mixing's private methods        #
# -------------------------------------------------- #
#
#
# -------- #
#  Corpus  #
# -------- #
#
Corpus = {}
Corpus.dict = () -> return @corpus
Corpus.load = (corpus) ->
  if _.isObject(corpus) is true
    @corpus = corpus
  else
    @corpus = require corpus
  return
#
# Now making methods private. Only indirectly exposing Corpus
#
Corpus.export = () ->
  return Corpus.dict.apply Corpus
#
Corpus.export.load = (corpus) ->
  Corpus.load corpus
  return
#
# --------------- #
#   Spell check   #
# --------------- #
#
# This is the main function, it validates the user input, call helper
# functions, user feedback and decides if no match has been found.
#
Spell = {}
Spell.dict00 = {}
Spell.dict01 = spell()
Spell.suggestions = Object.create null
Spell.suggestions[0] = []
# force use of less module
Spell.FORCE = no
Spell.CLI = no
Spell.reset = () ->
  @suggestions = Object.create null
  @suggestions[0] = []
#
Spell.main = (input, force = no, cli = no) ->
  @FORCE = force
  @CORPUS = _.e.corpus()
  found = no
  #
  if _.isUndefined @CORPUS
    throw new Error('corpus object have being loaded')
  else
    source = @CORPUS
  if cli is yes then @CLI = yes
  if force is yes
    @dict01.load corpus: source
  else
    @dict00 = source
  if input.length <= 1
    @suggestions = Object.create null
    @suggestions[0] = []
    return
  #
  # I chose to not remove non ALPHANUM characters because in this way the
  # app is more robust. It could be used by non English languages, assuming
  # a language corpus is provided.
  #
  if typeof(input) isnt 'string' or _.isUndefined input
    throw new Error('User input must be a string')
  #
  if @FORCE is yes and @CLI is yes then put 'Loading...'
  #
  # Performing a basic spell checking.
  if @spellCheck(input) is true
    found = yes
    if @FORCE is yes and @CLI is yes then print ''
    ans = @sortMatches()
    @reset()
    return ans
  #
  # Fixing, generating and testing repeated letters in word candidates and
  # spell checking them.
  list00 = @fixRepeated input
  _.each list00, (word) =>
    if @FORCE is yes and @CLI is yes then put '.'
    if @spellCheck(word) is true then found = yes
  #
  if found is yes
    if @FORCE is yes and @CLI is yes then print ''
    ans = @sortMatches()
    @reset()
    return ans
  #
  # Based on previously generated list, now swapping vowels and extending
  # the candidates list and spell checking for the last time.
  list01 = []
  _.each list00, (word) =>
    list01.push @fixVowels word
  #
  candidates = _.uniq(_.flatten([list00, list01]))
  _.each candidates, (word) =>
    if @FORCE is yes and @CLI is yes then put '.'
    if @spellCheck(word) is true then found = yes
  #
  if found is yes
    if @FORCE is yes and @CLI is yes then print ''
    ans = @sortMatches()
    @reset()
    return ans
  #
  if found is no
    if @FORCE is yes and @CLI is yes then print ''
    ans = 'NO SUGGESTION'
    @reset()
    return ans
  return
#
# It sorts which word to display if there are multiple matches.
#
Spell.sortMatches = ->
  #
  # Very likely there will be more then one match. The selection criteria
  # goes as follows.
  #   1st - Choose the longest word.
  #   2nd - Choose the most often used word.
  #
  wordLength = _.keys(@suggestions).sort((a, b) -> return b - a)[0]
  score = _.keys(@suggestions[wordLength]).sort((a, b) -> return b - a)[0]
  match = @suggestions[wordLength][score]
  originalInput = _.last @suggestions[0]
  #
  if match is originalInput
    return 'Spelling is correct'
  else
    return match
  return
#
# This function checks if a word has been spelled correctly and returns true
# if found.
#
Spell.spellCheck = (word) ->
  # Adding word to the suggestion namespace.
  @suggestions[0].unshift "#{word}"
  #
  # Taking care of the 1st class of spelling errors - case errors.
  word = word.toLowerCase()
  #
  if @FORCE is yes
    matches = @dict01.suggest word
    if matches.length isnt 0
      found = yes
      score = matches[0].score
      match = matches[0].word
      length = matches[0].word.length
  else
    score = @dict00[word]
    if score isnt undefined
      found = yes
      match = word
      length = word.length
  #
  if found is yes
    @suggestions[length] = @suggestions[length] or Object.create null
    @suggestions[length][score] = match
    return true
  return
#
# Taking care of the 2nd class of spelling errors - repeated letters.
#
# This function finds all repeated letters in the word, and it returns an
# array with possible word spelling.
#
Spell.fixRepeated = (word) ->
  tmp00 = []
  candidatesList = []
  letters = word.toLowerCase().split ''
  #
  # Finding which letter repeats and which don't.
  #
  _.each letters, (letter, index) ->
    if index isnt 0
      if letter is letters[index - 1]
        tmp00.pop()
        tmp00.push [letter, true]
      else
        tmp00.push [letter, false]
    else
      tmp00.push [letter, false]
    return
  #
  # As far as I'm concerned, there are never more then 2 repeated letters
  # in a English word. Whenever there is a pair of repeated letters, there
  # will always be only one at a time, and it will never be at the
  # beginning of a word.
  #
  # Now, creating a list of possible spellings based on the rules set above.
  #
  _.each tmp00, (item, index) ->
    letter = item[0]
    if index isnt 0
      repeated = item[1]
    else
      repeated = false
    #
    newWord = []
    _.each tmp00, (item2, index2) ->
      newWord.push item2[0]
      if index is index2 and repeated is true
        newWord.push item2[0]
    candidatesList.push newWord.join ''
  return candidatesList
#
# Taking care of the 3nd class of spelling errors - incorrect vowels.
#
# This function swaps all vowels in a word and returns an array with
# all possible ways the word's vowels can be swapped
#
Spell.fixVowels = (word) ->
  vowels = 'aeiou'.split ''
  letters = word.toLowerCase().split ''
  #
  newWord = []
  _.each letters, (letter) ->
    if _.intersection(vowels, [letter]).length isnt 0
      newWord.push vowels
    else
      newWord.push letter
  #
  candidatesList = ['']
  _.each newWord, (letter) ->
    tmp00 = []
    if _.isArray letter
      _.each letter, (vowel) ->
        _.each candidatesList, (candidate) ->
          tmp00.push "#{candidate}#{vowel}"
    else
      _.each candidatesList, (candidate) ->
        tmp00.push "#{candidate}#{letter}"
    candidatesList = tmp00
  return candidatesList
#
# Now making methods private. Only indirectly exposing Spell.main
#
Spell.export = (word...) ->
  return Spell.main.apply Spell, word
#
# ---------- #
#  misspell  #
# ---------- #
#
# Returns a misspelled word which contains:
#  - random letters added into the word.
#  - random case letters (upper/lower)
#  - random numbers of repetead letters
#
misspell = (word, difficulty = 'easy') ->
  alpha = 'abcdefghijklmnopqrstuvwxyz'.split ''
  letters = word.split ''
  newWord = []
  #
  if difficulty is 'hard'
    num = 5
  else if difficulty is 'medium'
    num = 20
  else if difficulty is 'easy'
    num = 100
  #
  _.each letters, (letter) ->
    oldLetter = letter
    #
    # adding repeated letters
    if _.e.randNum(20) is 1
      _.times _.e.randNum(4), ->
        newWord.push letter
    #
    # choosing a random letter to add to the misspelled word. 
    if _.e.randNum(num) is 1
      letter = alpha[_.e.randNum(alpha.length) - 1]
    #
    # Addind random upper case letters
    if _.e.randNum(2) is 1
      # weird bug here !:(
      try
        letter = letter.toUpperCase()
      catch err
        letter = oldLetter
    # another weird bug !:(
    if letter is '' then letter = oldLetter
    #
    newWord.push letter
  newWord = newWord.join ''
  #
  # Somewhow, some words still doesn't change, so start over again.
  if newWord.toLowerCase() is word
    misspell word, difficulty
  else
    return newWord
#
# ---------- #
#  randNum   #
# ---------- #
#
# Returns a number between 0 and num
#
randNum = (num) -> return Math.floor((num + 1)*Math.random())
#
# ---------- #
#  randWord  #
# ---------- #
#
# Returns a random word from the corpus
#
randWord = (max = Infinity, min = -Infinity) ->
  corpus = _.e.corpus()
  if _.isUndefined corpus
    throw new Error '\n_.dict has not being loaded\n'
  #
  words = _.keys corpus
  len = words.length
  word = words[_.e.randNum(len) - 1]
  if word.length < min
    randWord max = max, min = min
  else if word.length > max
    randWord max = max, min = min
  else
    return {
      word: word
      score: corpus[word]
    }
#
# ------- #
#  delay  #
# ------- #
#
delay = (ms, cb) ->
  #
  # TODO: if ms = 0, process.nextTick on node is more efficient then 
  # setTimeout. Must create a test to sense the env
  #
  setTimeout -> 
    cb()
  , ms
#
# Creating the underscore mixins. Keeping all my mixins under the _.e
# namespace. Avoiding collisions.
#
E = () -> return
E.print = print
E.put = put
E.corpus = Corpus.export
E.spell = Spell.export
E.misspell = misspell
E.randNum = randNum
E.randWord = randWord
E.delay = delay
#
_.mixin e: E
#
# Exporting the extended underscore
#
module.exports = _
#
